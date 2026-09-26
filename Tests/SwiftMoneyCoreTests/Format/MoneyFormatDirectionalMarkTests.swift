import SwiftMoneyCore
import Testing

// Directional marks are additive to the affix model: a mark-carrying token renders at the byte length
// `DirectionalMark.scalar` implies, for both `format(_:)` and `runs(_:options:)`, and is never dropped.
@Suite("MoneyFormat directional marks")
struct MoneyFormatDirectionalMarkTests {

    static func money(_ minorUnits: Int64, _ iso: CurrencyCode) -> Money {
        guard let currency = Currency(iso: iso) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return Money(minorUnits: minorUnits, currency: currency)
    }

    // A right-to-left mark leads the arrangement, matching the shape CLDR gives most `ar-*` locales:
    // RLM, sign, digits, spacing, then the trailing currency symbol.
    static let riyal = MoneyFormat(
        symbol: "ر.س.",
        pattern: MoneyFormatPattern(
            positive: MoneyFormatAffixes(
                prefix: [.directionalMark(.rightToLeft), .sign], suffix: [.currencySpacing, .currency]
            ),
            negative: MoneyFormatAffixes(
                prefix: [.directionalMark(.rightToLeft), .sign], suffix: [.currencySpacing, .currency]
            ),
            accountingNegative: MoneyFormatAffixes(
                prefix: [.directionalMark(.rightToLeft), .sign], suffix: [.currencySpacing, .currency]
            )
        ),
        currencySpacing: "\u{00A0}"
    )

    // A second right-to-left mark interior to the suffix, immediately before the currency symbol,
    // matching the shape CLDR gives `he`.
    static let shekel = MoneyFormat(
        symbol: "₪",
        pattern: MoneyFormatPattern(
            positive: MoneyFormatAffixes(
                prefix: [.directionalMark(.rightToLeft), .sign],
                suffix: [.currencySpacing, .directionalMark(.rightToLeft), .currency]
            ),
            negative: MoneyFormatAffixes(
                prefix: [.directionalMark(.rightToLeft), .sign],
                suffix: [.currencySpacing, .directionalMark(.rightToLeft), .currency]
            ),
            accountingNegative: MoneyFormatAffixes(
                prefix: [.directionalMark(.rightToLeft), .sign],
                suffix: [.currencySpacing, .directionalMark(.rightToLeft), .currency]
            )
        ),
        currencySpacing: "\u{00A0}"
    )

    @Test("A leading mark renders before the sign for both a positive and a negative amount")
    func rendersLeadingMark() {
        let positive = Self.riyal.format(Self.money(1_00, "SAR"))
        let negative = Self.riyal.format(Self.money(-1_00, "SAR"))

        #expect(positive == "\u{200F}1.00\u{00A0}ر.س.")
        #expect(negative == "\u{200F}-1.00\u{00A0}ر.س.")
    }

    @Test("An always-shown positive sign renders after the mark")
    func alwaysSignRendersAfterMark() {
        let shown = Self.riyal.format(Self.money(1_00, "SAR"), options: .init(sign: .always))
        #expect(shown == "\u{200F}+1.00\u{00A0}ر.س.")
    }

    @Test("The rendered length matches the buffer exactly, with no trap or truncation")
    func lengthMatchesBuffer() {
        let expected = "\u{200F}1.00\u{00A0}ر.س.".utf8.count
        #expect(Self.riyal.format(Self.money(1_00, "SAR")).utf8.count == expected)
    }

    @Test("An interior mark before the currency symbol renders in place, for both signs")
    func rendersInteriorMark() {
        let positive = Self.shekel.format(Self.money(1_00, "ILS"))
        let negative = Self.shekel.format(Self.money(-1_00, "ILS"))

        #expect(positive == "\u{200F}1.00\u{00A0}\u{200F}₪")
        #expect(negative == "\u{200F}-1.00\u{00A0}\u{200F}₪")
    }

    @Test("runs() emits a leading directionalMark run, and concatenating the runs equals format(_:)")
    func runsEmitLeadingDirectionalMark() {
        let money = Self.money(1_00, "SAR")
        let runs = Self.riyal.runs(money, options: .init())

        #expect(runs.first == .directionalMark(.rightToLeft))
        #expect(runs.map(\.text).joined() == Self.riyal.format(money))
    }

    @Test("runs() emits both a leading and an interior directionalMark run")
    func runsEmitInteriorDirectionalMark() {
        let money = Self.money(1_00, "ILS")
        let runs = Self.shekel.runs(money, options: .init())

        #expect(runs.filter { $0 == .directionalMark(.rightToLeft) }.count == 2)
        #expect(runs.last == .currency("₪"))
        #expect(runs.map(\.text).joined() == Self.shekel.format(money))
    }

    @Test("A negative amount's runs also carry the mark")
    func negativeRunsCarryMark() {
        let money = Self.money(-1_00, "SAR")
        let runs = Self.riyal.runs(money, options: .init())

        #expect(runs.contains(.directionalMark(.rightToLeft)))
        #expect(runs.map(\.text).joined() == Self.riyal.format(money))
    }
}
