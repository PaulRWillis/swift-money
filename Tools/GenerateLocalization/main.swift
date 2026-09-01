// A dev-only tool. Reads the pinned CLDR JSON (fetched via npm into Tools/cldr/node_modules) and emits
// the Swift data tables that SwiftMoneyLocalization composes into a MoneyFormat. Not part of any library
// product; run with `swift run GenerateSwiftMoneyLocalization` after `npm ci` in Tools/cldr.
//
// CLDR encodes currency spacing two ways: a literal space inside the format pattern (e.g. the NBSP in
// "#,##0.00 ¤"), and a currencySpacing rule that inserts a space between the number and a symbol whose
// touching character is neither a Unicode Symbol nor a separator (so ISO codes like "GBP" get a space,
// but "£"/"€" do not). This tool resolves that rule at generation time — using the full Swift Unicode
// tables, which Embedded lacks — and bakes the resulting spacing string into the data, so the runtime
// target needs no Unicode-category lookups.

import Foundation

let cldrVersion = "48.0.0"
let locales = ["en", "en-GB", "de", "fr", "ja"]

let repoRoot = FileManager.default.currentDirectoryPath
let cldrMain = "\(repoRoot)/Tools/cldr/node_modules/cldr-numbers-full/main"
let outputPath = "\(repoRoot)/Sources/SwiftMoneyLocalization/Generated/CLDRTables.swift"

// MARK: - CLDR reading

func json(_ path: String) -> [String: Any] {
    guard let data = FileManager.default.contents(atPath: path),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        fatalError("Could not read CLDR JSON at \(path)")
    }
    return object
}

func numbers(_ locale: String) -> [String: Any] {
    let root = json("\(cldrMain)/\(locale)/numbers.json")
    let main = root["main"] as! [String: Any]
    let entry = main[locale] as! [String: Any]
    return entry["numbers"] as! [String: Any]
}

func currencies(_ locale: String) -> [String: [String: String]] {
    let root = json("\(cldrMain)/\(locale)/currencies.json")
    let main = root["main"] as! [String: Any]
    let entry = main[locale] as! [String: Any]
    let numbers = entry["numbers"] as! [String: Any]
    let currencies = numbers["currencies"] as! [String: Any]
    return currencies.mapValues { $0 as! [String: String] }
}

// MARK: - Pattern parsing

enum Placement: String { case before = ".before", after = ".after" }

let numberChars: Set<Character> = ["#", "0", ".", ",", "\u{00A0}\u{00A0}".first!]  // #,0,. and , only
let integerNumberChars: Set<Character> = ["#", "0", ",", "."]

struct ParsedPattern {
    let placement: Placement
    let patternSpacing: String
    let primaryGroupingSize: Int
    let secondaryGroupingSize: Int
    let accountingParentheses: Bool
}

func parse(standard: String, accounting: String) -> ParsedPattern {
    let positive = String(standard.split(separator: ";").first ?? Substring(standard))

    let symbolIndex = positive.firstIndex(of: "¤")!
    let firstNumber = positive.firstIndex { integerNumberChars.contains($0) }!

    let placement: Placement = symbolIndex < firstNumber ? .before : .after
    let patternSpacing: String
    if placement == .before {
        // Chars between ¤ and the first number character.
        patternSpacing = String(positive[positive.index(after: symbolIndex) ..< firstNumber])
    } else {
        // Chars between the last number character and ¤.
        let lastNumber = positive.lastIndex { integerNumberChars.contains($0) }!
        patternSpacing = String(positive[positive.index(after: lastNumber) ..< symbolIndex])
    }

    // Grouping: the integer subpattern (before the decimal point), split on the group separator.
    let integerPart = positive.prefix { $0 != "." }.filter { $0 == "#" || $0 == "0" || $0 == "," }
    let groups = integerPart.split(separator: ",", omittingEmptySubsequences: false).map(\.count)
    let primary = groups.last ?? 3
    let secondary = groups.count >= 3 ? groups[groups.count - 2] : primary

    // Accounting wraps negatives in parentheses when its negative subpattern does.
    let accountingNegative = accounting.split(separator: ";").dropFirst().first ?? ""
    let accountingParentheses = accountingNegative.contains("(")

    return ParsedPattern(
        placement: placement,
        patternSpacing: patternSpacing,
        primaryGroupingSize: primary,
        secondaryGroupingSize: secondary,
        accountingParentheses: accountingParentheses
    )
}

// MARK: - Currency spacing (resolved here, baked into the data)

func isSymbolOrSeparator(_ character: Character) -> Bool {
    guard let scalar = character.unicodeScalars.first else { return false }
    switch scalar.properties.generalCategory {
    case .currencySymbol, .modifierSymbol, .mathSymbol, .otherSymbol,
         .spaceSeparator, .lineSeparator, .paragraphSeparator:
        return true
    default:
        return false
    }
}

// The space between symbol and digits for a resolved symbol string: the pattern's literal spacing if it
// has any, else the currencySpacing insertion when the touching character is not a symbol/separator.
func spacing(for symbol: String, placement: Placement, patternSpacing: String, insertBetween: String) -> String {
    if !patternSpacing.isEmpty {
        return patternSpacing
    }
    let boundary = placement == .before ? symbol.last : symbol.first
    guard let boundary, !isSymbolOrSeparator(boundary) else {
        return ""
    }
    return insertBetween
}

// MARK: - Swift emission

func quote(_ string: String) -> String {
    var escaped = ""
    for scalar in string.unicodeScalars {
        switch scalar {
        case "\\": escaped += "\\\\"
        case "\"": escaped += "\\\""
        case _ where scalar.value < 0x20 || scalar.value > 0x7E:
            escaped += "\\u{\(String(scalar.value, radix: 16, uppercase: true))}"
        default:
            escaped.unicodeScalars.append(scalar)
        }
    }
    return "\"\(escaped)\""
}

var numberFormatLines: [String] = []
var currencyBlocks: [String] = []

for locale in locales {
    let n = numbers(locale)
    let symbols = n["symbols-numberSystem-latn"] as! [String: String]
    let formats = n["currencyFormats-numberSystem-latn"] as! [String: Any]
    let standard = formats["standard"] as! String
    let accounting = formats["accounting"] as! String
    let spacingRule = formats["currencySpacing"] as! [String: Any]
    let afterCurrency = spacingRule["afterCurrency"] as! [String: String]
    let insertBetween = afterCurrency["insertBetween"] ?? " "

    let parsed = parse(standard: standard, accounting: accounting)

    // ISO code is always letters, so it takes the insertion (or the pattern's literal spacing).
    let isoSpacing = spacing(for: "AAA", placement: parsed.placement, patternSpacing: parsed.patternSpacing, insertBetween: insertBetween)

    numberFormatLines.append("""
            \(quote(locale)): LocaleNumberFormat(
                decimalSeparator: \(quote(symbols["decimal"]!)),
                groupingSeparator: \(quote(symbols["group"]!)),
                minusSign: \(quote(symbols["minusSign"] ?? "-")),
                primaryGroupingSize: \(parsed.primaryGroupingSize),
                secondaryGroupingSize: \(parsed.secondaryGroupingSize),
                placement: \(parsed.placement.rawValue),
                isoCodeSpacing: \(quote(isoSpacing)),
                accountingParentheses: \(parsed.accountingParentheses)
            ),
    """)

    var entries: [String] = []
    for (code, fields) in currencies(locale).sorted(by: { $0.key < $1.key }) {
        guard let symbol = fields["symbol"], symbol != code else {
            continue   // no distinct symbol; the runtime falls back to the code
        }
        let narrow = fields["symbol-alt-narrow"] ?? symbol
        let standardSpacing = spacing(for: symbol, placement: parsed.placement, patternSpacing: parsed.patternSpacing, insertBetween: insertBetween)
        let narrowSpacing = spacing(for: narrow, placement: parsed.placement, patternSpacing: parsed.patternSpacing, insertBetween: insertBetween)
        entries.append("            \(quote(code)): CurrencyDisplay(standardSymbol: \(quote(symbol)), standardSpacing: \(quote(standardSpacing)), narrowSymbol: \(quote(narrow)), narrowSpacing: \(quote(narrowSpacing))),")
    }

    currencyBlocks.append("""
            \(quote(locale)): [
    \(entries.joined(separator: "\n"))
            ],
    """)
}

let output = """
// Generated from CLDR \(cldrVersion) by GenerateSwiftMoneyLocalization. Do not edit by hand.
// Regenerate with: (cd Tools/cldr && npm ci) && swift run GenerateSwiftMoneyLocalization

import SwiftMoneyCore

extension MoneyLocalization {
    static let cldrVersion = \(quote(cldrVersion))

    static let numberFormats: [String: LocaleNumberFormat] = [
    \(numberFormatLines.joined(separator: "\n"))
    ]

    static let currencyDisplays: [String: [String: CurrencyDisplay]] = [
    \(currencyBlocks.joined(separator: "\n"))
    ]
}
"""

try? FileManager.default.createDirectory(
    atPath: (outputPath as NSString).deletingLastPathComponent,
    withIntermediateDirectories: true
)
try! output.write(toFile: outputPath, atomically: true, encoding: .utf8)
print("Wrote \(outputPath) from CLDR \(cldrVersion) for locales: \(locales.joined(separator: ", "))")
