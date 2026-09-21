import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

// The correctness backbone for the non-ICU format engine: the engine and `Decimal.FormatStyle.Currency`
// are driven from the SAME MoneyFormatOptions, so a passing test proves the non-ICU output equals ICU's
// for that modifier combination. Lives in the Foundation target because it depends on ICU. ASCII locales
// keep the comparison unambiguous; the non-ASCII assembly is pinned in the Core test target.
@Suite("MoneyFormat ICU parity")
struct MoneyFormatICUParityTests {

    // English's arrangement: the symbol, then the digits, with a minus in front of a negative and
    // parentheses for the accounting form.
    static let symbolFirst = MoneyFormatPattern(
        positive: [.sign, .currency, .currencyGap, .integerDigits, .decimalSeparator, .fractionDigits],
        negative: [.sign, .currency, .currencyGap, .integerDigits, .decimalSeparator, .fractionDigits],
        accountingNegative: [
            .literal("("), .currency, .currencyGap, .integerDigits, .decimalSeparator, .fractionDigits, .literal(")"),
        ]
    )

    static let dollar = MoneyFormat(symbol: "$", pattern: symbolFirst)
    static let sterling = MoneyFormat(symbol: "£", pattern: symbolFirst)

    static func money(_ minorUnits: Int64, _ iso: CurrencyCode) -> Money {
        guard let currency = Currency(iso: iso) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return Money(minorUnits: minorUnits, currency: currency)
    }

    // ICU's rendering of the same amount under the same options — each modifier applied only when it
    // differs from the default, since setting a modifier to its own default makes ICU drop the symbol.
    static func icu(_ minorUnits: Int64, _ iso: String, _ localeID: String, _ options: MoneyFormatOptions) -> String {
        let places = 2   // USD and GBP
        let digits: Int
        let rule: RoundingRule
        switch options.precision {
        case .currencyScale: (digits, rule) = (places, .toNearestOrEven)
        case .fixed(let length, let rounding): (digits, rule) = (Int(length), rounding)
        }
        var style = Decimal.FormatStyle.Currency(code: iso, locale: Locale(identifier: localeID))
            .precision(.fractionLength(digits))

        if options.grouping == .never {
            style = style.grouping(.never)
        }
        if options.decimalSeparator == .always {
            style = style.decimalSeparator(strategy: .always)
        }
        switch options.sign {
        case .automatic: break
        case .never: style = style.sign(strategy: .never)
        case .always: style = style.sign(strategy: .always())
        case .accounting: style = style.sign(strategy: .accounting)
        }
        if rule != .toNearestOrEven {
            style = style.rounded(rule: rule)
        }

        return style.format(Decimal(minorUnits) / Decimal(100))
    }

    static let ascii: [(iso: String, locale: String, format: MoneyFormat)] = [
        ("USD", "en_US", dollar),
        ("GBP", "en_GB", sterling),
    ]

    static let amounts: [Int64] = [0, 1_00, 9_99, 1_234_56, -1_234_56, 1_234_567_89, -9_99, 2_50, 3_50]

    func expectMatchesICU(_ options: MoneyFormatOptions, _ label: String) {
        for amount in Self.amounts {
            for entry in Self.ascii {
                let code = CurrencyCode(string: entry.iso) ?? "XXX"
                let engine = entry.format.format(Self.money(amount, code), options: options)
                let icu = Self.icu(amount, entry.iso, entry.locale, options)
                #expect(engine == icu, "\(label) \(entry.iso) \(amount): '\(engine)' vs ICU '\(icu)'")
            }
        }
    }

    @Test("Default options match ICU")
    func defaults() {
        expectMatchesICU(MoneyFormatOptions(), "default")
    }

    @Test("Sign strategies match ICU")
    func sign() {
        expectMatchesICU(MoneyFormatOptions(sign: .never), "sign never")
        expectMatchesICU(MoneyFormatOptions(sign: .always), "sign always")
        expectMatchesICU(MoneyFormatOptions(sign: .accounting), "sign accounting")
    }

    @Test("Grouping off matches ICU")
    func grouping() {
        expectMatchesICU(MoneyFormatOptions(grouping: .never), "no grouping")
    }

    @Test("Always-on decimal separator matches ICU")
    func decimalSeparator() {
        expectMatchesICU(MoneyFormatOptions(decimalSeparator: .always), "separator always")
    }

    @Test("Fraction length matches ICU (round and pad)")
    func precision() {
        expectMatchesICU(MoneyFormatOptions(precision: .fixed(0, rounding: .toNearestOrEven)), "fixed 0")
        expectMatchesICU(MoneyFormatOptions(precision: .fixed(1, rounding: .toNearestOrEven)), "fixed 1")
        expectMatchesICU(MoneyFormatOptions(precision: .fixed(4, rounding: .toNearestOrEven)), "fixed 4")
    }

    @Test("Every rounding rule matches ICU when precision drops digits")
    func roundingRules() {
        let rules: [RoundingRule] = [.down, .up, .towardZero, .awayFromZero, .toNearestOrAwayFromZero]
        for rule in rules {
            expectMatchesICU(MoneyFormatOptions(precision: .fixed(0, rounding: rule)), "round \(rule)")
            expectMatchesICU(MoneyFormatOptions(precision: .fixed(1, rounding: rule)), "round \(rule) @1")
        }
    }
}
