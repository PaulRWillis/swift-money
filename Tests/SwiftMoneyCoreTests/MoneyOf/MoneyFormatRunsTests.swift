import SwiftMoneyCore
import Testing

// The typed-run form of the render. The load-bearing property is that concatenating a run list gives
// exactly `format(_:options:)`'s string; the rest pin how the pieces are split and tagged, which is
// what a Foundation AttributedString renderer relies on.
@Suite("MoneyFormat runs")
struct MoneyFormatRunsTests {

    static func pattern(currencyFirst: Bool, accountingParentheses: Bool = true) -> MoneyFormatPattern {
        let (prefixBody, suffixBody): ([MoneyFormatToken], [MoneyFormatToken]) = currencyFirst
            ? ([.currency, .currencySpacing], [])
            : ([], [.currencySpacing, .currency])
        let signed = MoneyFormatAffixes(prefix: [.sign] + prefixBody, suffix: suffixBody)

        return MoneyFormatPattern(
            positive: signed,
            negative: signed,
            accountingNegative: accountingParentheses
                ? MoneyFormatAffixes(prefix: [.literal("(")] + prefixBody, suffix: suffixBody + [.literal(")")])
                : signed
        )
    }

    static func money(_ minorUnits: Int64, _ iso: CurrencyCode) -> Money {
        guard let currency = Currency(iso: iso) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return Money(minorUnits: minorUnits, currency: currency)
    }

    static let dollar = MoneyFormat(symbol: "$", pattern: pattern(currencyFirst: true))

    @Test("Concatenating the runs gives the formatted string")
    func runsConcatenateToFormat() {
        let euro = MoneyFormat(
            symbol: "€", pattern: Self.pattern(currencyFirst: false), currencySpacing: "\u{00A0}",
            decimalSeparator: ",", grouping: .repeating(3, separator: ".")
        )
        let cases: [(MoneyFormat, Int64, CurrencyCode, MoneyFormatOptions)] = [
            (Self.dollar, 1_234_56, "USD", .init()),
            (Self.dollar, -1_234_56, "USD", .init()),
            (Self.dollar, -1_234_56, "USD", .init(sign: .accounting)),
            (Self.dollar, 0, "USD", .init()),
            (euro, 1_234_567_89, "EUR", .init()),
            (Self.dollar, 1_00, "USD", .init(grouping: .never)),
            (Self.dollar, 1_00, "USD", .init(decimalSeparator: .always)),
            (Self.dollar, 1_00, "USD", .init(sign: .always)),
            (Self.dollar, 1_234_56, "USD", .init(precision: .fixed(1, rounding: .toNearestOrEven))),
            (Self.dollar, 1_234_56, "USD", .init(precision: .fixed(4, rounding: .up))),
        ]

        for (format, minorUnits, iso, options) in cases {
            let money = Self.money(minorUnits, iso)
            let joined = format.runs(money, options: options).map(\.text).joined()
            #expect(joined == format.format(money, options: options))
        }
    }

    @Test("A grouped positive splits the digits from the separators")
    func groupedPositiveSplits() {
        let runs = Self.dollar.runs(Self.money(1_234_56, "USD"), options: .init())

        #expect(runs == [
            .currency("$"),
            .integerDigits("1"), .groupingSeparator(","), .integerDigits("234"),
            .decimalSeparator("."), .fractionDigits("56"),
        ])
    }

    @Test("A negative leads with a sign run; a positive has none")
    func signRun() {
        #expect(Self.dollar.runs(Self.money(-5_00, "USD"), options: .init()).first == .sign("-"))
        #expect(!Self.dollar.runs(Self.money(5_00, "USD"), options: .init()).contains { $0 == .sign("-") })
    }

    @Test("Accounting parentheses are literal runs, with no sign run")
    func accountingHasLiteralsNotSign() {
        let runs = Self.dollar.runs(Self.money(-5_00, "USD"), options: .init(sign: .accounting))

        #expect(runs.first == .literal("("))
        #expect(runs.last == .literal(")"))
        #expect(!runs.contains { if case .sign = $0 { true } else { false } })
    }

    @Test("A zero-fraction currency has no decimal-separator or fraction runs")
    func zeroFractionOmitsDecimalRuns() {
        let yen = MoneyFormat(symbol: "¥", pattern: Self.pattern(currencyFirst: true))
        let runs = yen.runs(Self.money(1_234, "JPY"), options: .init())

        #expect(runs == [
            .currency("¥"), .integerDigits("1"), .groupingSeparator(","), .integerDigits("234"),
        ])
    }

    @Test("Indian grouping splits three then twos")
    func indianGrouping() {
        let rupee = MoneyFormat(
            symbol: "₹", pattern: Self.pattern(currencyFirst: true),
            grouping: .digits(primary: 3, secondary: 2, separator: ",")
        )
        let runs = rupee.runs(Self.money(1_23_456_78, "INR"), options: .init())

        #expect(runs == [
            .currency("₹"),
            .integerDigits("1"), .groupingSeparator(","),
            .integerDigits("23"), .groupingSeparator(","),
            .integerDigits("456"),
            .decimalSeparator("."), .fractionDigits("78"),
        ])
    }
}
