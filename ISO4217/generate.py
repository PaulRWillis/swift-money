#!/usr/bin/env python3
"""Generate the ISO 4217 currency table from the maintenance agency's own list.

    python3 ISO4217/generate.py

Reads `ISO4217/list-one.xml`, the list SIX Group publishes as ISO 4217's maintenance agency, and
writes `Sources/SwiftMoney/Currency+ISO4217.swift`. The list is vendored rather than fetched so that
a regeneration is reproducible and the published date is recorded alongside what came out of it.

To take a newer list:

    curl -o ISO4217/list-one.xml \\
      https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml
"""

import pathlib
import re
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "ISO4217" / "list-one.xml"
OUTPUT = ROOT / "Sources" / "SwiftMoney" / "Currency+ISO4217.swift"
TEST_OUTPUT = ROOT / "Tests" / "SwiftMoneyTests" / "CurrencyISO4217Tests.swift"

# `try` is the only ISO code whose lowercased form Swift reserves.
SWIFT_KEYWORDS = {"try"}

# ISO's exponent field can only express powers of ten, so it records these two as 2 and footnotes
# them "divby5" instead. The table follows ISO, because that is what payment systems assume, and the
# note says so where a reader would otherwise be misled.
DIVIDES_BY_FIVE = {
    "MRU": "five khoums",
    "MGA": "five iraimbilanja",
}


def currencies(path):
    """Every code the list gives a numeric minor unit for, by code, with its name and exponent."""
    root = ET.parse(path).getroot()
    published = root.attrib["Pblshd"]
    found = {}

    for entry in root.iter("CcyNtry"):
        code = (entry.findtext("Ccy") or "").strip()
        minor = (entry.findtext("CcyMnrUnts") or "").strip()

        # A row without a code is a territory with no universal currency, and a minor unit of "N.A."
        # is ISO declining to state one: the metals, the bond market units, XDR, XSU, XUA, XTS, XXX.
        if not code or not minor.isdigit() or code in found:
            continue

        found[code] = {
            "code": code,
            "name": (entry.findtext("CcyNm") or "").strip(),
            "scale": 10 ** int(minor),
        }

    return published, [found[code] for code in sorted(found)]


def identifier(code):
    lowered = code.lower()

    return f"`{lowered}`" if lowered in SWIFT_KEYWORDS else lowered


def grouped(scale):
    """`100_000_000` rather than `100000000`, as the rest of the sources write large literals."""
    return f"{scale:,}".replace(",", "_")


def documentation(currency):
    lines = [f"/// {currency['name']}."]

    if currency["code"] in DIVIDES_BY_FIVE:
        lines += [
            "///",
            f"/// Divides into {DIVIDES_BY_FIVE[currency['code']]}, which ISO 4217 cannot express: its",
            "/// exponent field holds a power of ten, so it records 2 and footnotes the currency",
            "/// `divby5`. The scale here follows ISO, because that is what payment systems assume.",
        ]

    return lines


def values(found):
    lines = ["public extension Currency {"]

    for index, currency in enumerate(found):
        if index:
            lines.append("")
        lines += [f"    {line}" for line in documentation(currency)]
        lines.append(
            f"    static let {identifier(currency['code'])} = "
            f'Currency(code: "{currency["code"]}", unitScale: {grouped(currency["scale"])})'
        )

    return lines + ["}"]


def types(found):
    lines = ["public extension Currencies {"]

    for index, currency in enumerate(found):
        if index:
            lines.append("")
        lines += [f"    {line}" for line in documentation(currency)]
        lines += [
            f"    enum {currency['code']}: CurrencyType {{",
            f"        public static let currency: Currency = .{identifier(currency['code'])}",
            "    }",
        ]

    return lines + ["}"]


def packed(code):
    """A code as the single word `CurrencyCode` stores, first character in the high byte."""
    value = 0

    for byte in code.encode():
        value = value << 8 | byte

    return value << (8 * (8 - len(code)))


def lookup(found):
    lines = [
        "public extension Currency {",
        "    /// The ISO 4217 currency a code names.",
        "    ///",
        "    /// ```swift",
        '    /// Currency(iso: "GBP")   // GBP, 100 subunits',
        '    /// Currency(iso: "LTY")   // nil',
        "    /// ```",
        "    init?(iso code: CurrencyCode) {",
        "        // Switched on the packed word rather than the code, so the compiler can build a",
        "        // search over integers. Every case is checked by the tests, which look up all of",
        "        // these by their spelling.",
        "        switch code.packedValue {",
    ]

    for currency in found:
        code = currency["code"]
        lines.append(
            f"        case 0x{packed(code):016X}: self = .{identifier(code)}   // {code}"
        )

    return lines + [
        "        default: return nil",
        "        }",
        "    }",
        "}",
    ]


def generate(published, found):
    header = [
        f"// Generated from ISO 4217's list-one.xml, published {published}. Do not edit by hand:",
        "// run `python3 ISO4217/generate.py` instead.",
        "//",
        "// Codes the list gives no minor unit for are absent, because a scale of at least one would",
        "// assert a subdivision the standard declines to state. That is the metals XAU, XAG, XPT and",
        "// XPD, the bond market units XBA to XBD, XDR, XSU, XUA, and the reserved XTS and XXX. Java's",
        "// `Currency.getDefaultFractionDigits()` reports -1 for the same set rather than invent one.",
        "",
    ]

    return "\n".join(header + values(found) + ["", ""] + types(found) + ["", ""] + lookup(found)) + "\n"


def tests(published, found):
    """One case per currency, so that a code the generator mangles fails rather than lurking.

    An invalid code traps when its `Currency` is first touched, which nothing else here would do:
    the values are static, so a table of 165 that no test reads is a table nobody has run.
    """
    rows = ",\n".join(
        f'            (Currency.{identifier(c["code"])}, "{c["code"]}", {grouped(c["scale"])})'
        for c in found
    )

    return f"""// Generated from ISO 4217's list-one.xml, published {published}. Do not edit by hand:
// run `python3 ISO4217/generate.py` instead.

import SwiftMoney
import Testing

@Suite("ISO 4217 Table Tests")
struct CurrencyISO4217Tests {{

    @Test(
        "Every currency in the table carries its ISO code and scale",
        arguments: [
{rows},
        ] as [(Currency, String, Int64)]
    )
    func carriesItsCodeAndScale(_ currency: Currency, _ code: String, _ scale: Int64) {{
        #expect(String(currency.code) == code)
        #expect(Int64(currency.unitScale) == scale)
    }}

    @Test(
        "Every currency in the table is found by its code",
        arguments: [
{rows},
        ] as [(Currency, String, Int64)]
    )
    func isFoundByItsCode(_ currency: Currency, _ code: String, _: Int64) throws {{
        let found = try #require(CurrencyCode(string: code))

        #expect(Currency(iso: found) == currency)
    }}
}}
"""


def main():
    published, found = currencies(SOURCE)
    OUTPUT.write_text(generate(published, found))
    TEST_OUTPUT.write_text(tests(published, found))
    print(f"Wrote {len(found)} currencies to {OUTPUT.relative_to(ROOT)}, from the {published} list.")
    print(f"Wrote their tests to {TEST_OUTPUT.relative_to(ROOT)}.")


if __name__ == "__main__":
    main()
