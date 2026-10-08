import SwiftMoneyCore
import Testing

// Foundation-free assembly checks for the format engine: grouping (uniform and Indian), symbol
// placement, spacing, sign, zero fraction, and accounting parentheses — pinned deterministically with
// hand-written descriptors. ICU parity is verified separately in the Foundation test target, where ICU
// is available.
@Suite("MoneyFormat engine assembly")
struct MoneyFormatTests {

    // The two arrangements CLDR gives the locales below, written out once: currency first or last,
    // a minus in front of a negative, and parentheses for the accounting form unless stated.
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

    static let dollar = MoneyFormat(symbol: "$", pattern: pattern(currencyFirst: true))

    static func money(_ minorUnits: Int64, _ iso: CurrencyCode) -> Money {
        guard let currency = Currency(iso: iso) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return Money(minorUnits: minorUnits, currency: currency)
    }

    @Test("Symbol placement, grouping, spacing, sign, zero fraction, accounting")
    func assembly() {
        let eurDE = MoneyFormat(
            symbol: "€", pattern: Self.pattern(currencyFirst: false), currencySpacing: "\u{00A0}",
            decimalSeparator: ",", grouping: .repeating(3, separator: ".")
        )
        let eurFR = MoneyFormat(
            symbol: "€", pattern: Self.pattern(currencyFirst: false), currencySpacing: "\u{202F}",
            decimalSeparator: ",", grouping: .repeating(3, separator: "\u{202F}")
        )
        let jpy = MoneyFormat(symbol: "¥", pattern: Self.pattern(currencyFirst: true))
        let inr = MoneyFormat(
            symbol: "₹", pattern: Self.pattern(currencyFirst: true),
            grouping: .digits(primary: 3, secondary: 2, separator: ",", minGroupingDigits: 1)
        )

        // Symbol before, uniform grouping, sign, zero.
        #expect(Self.dollar.format(Self.money(1_234_56, "USD")) == "$1,234.56")
        #expect(Self.dollar.format(Self.money(-1_234_56, "USD")) == "-$1,234.56")
        #expect(Self.dollar.format(Self.money(0, "USD")) == "$0.00")
        #expect(Self.dollar.format(Self.money(1_234_567_89, "USD")) == "$1,234,567.89")

        // Symbol after, separators swapped, non-breaking space; and narrow-space French grouping.
        #expect(eurDE.format(Self.money(1_234_56, "EUR")) == "1.234,56\u{00A0}€")
        #expect(eurDE.format(Self.money(-1_234_56, "EUR")) == "-1.234,56\u{00A0}€")
        #expect(eurFR.format(Self.money(1_234_567_89, "EUR")) == "1\u{202F}234\u{202F}567,89\u{202F}€")

        // Zero-fraction currency: no separator, no fraction digits.
        #expect(jpy.format(Self.money(1_234, "JPY")) == "¥1,234")
        #expect(jpy.format(Self.money(1_234_567, "JPY")) == "¥1,234,567")

        // Indian grouping: rightmost group of three, then twos.
        #expect(inr.format(Self.money(1_23_456_78, "INR")) == "₹1,23,456.78")
        #expect(inr.format(Self.money(1234567890, "INR")) == "₹1,23,45,678.90")

        // Accounting parentheses wrap symbol and digits; positives stay plain.
        #expect(Self.dollar.format(Self.money(-1_234_56, "USD"), options: .init(sign: .accounting)) == "($1,234.56)")
        #expect(Self.dollar.format(Self.money(1_234_56, "USD"), options: .init(sign: .accounting)) == "$1,234.56")

        // Accounting can mark a negative with a minus instead of parentheses (e.g. de); positives stay plain.
        let euroMinus = MoneyFormat(
            symbol: "€", pattern: Self.pattern(currencyFirst: false, accountingParentheses: false),
            currencySpacing: "\u{00A0}",
            decimalSeparator: ",", grouping: .repeating(3, separator: ".")
        )
        #expect(euroMinus.format(Self.money(-1_234_56, "EUR"), options: .init(sign: .accounting)) == "-1.234,56\u{00A0}€")
        #expect(euroMinus.format(Self.money(1_234_56, "EUR"), options: .init(sign: .accounting)) == "1.234,56\u{00A0}€")

        // A descriptor with no grouping scheme never inserts separators, whatever the amount.
        let ungrouped = MoneyFormat(symbol: "$", pattern: Self.pattern(currencyFirst: true), grouping: .none)
        #expect(ungrouped.format(Self.money(1_234_567_89, "USD")) == "$1234567.89")

        // Grouping off, and always-on separator on a whole amount.
        #expect(Self.dollar.format(Self.money(1_234_56, "USD"), options: .init(grouping: .never)) == "$1234.56")
        #expect(jpy.format(Self.money(1_234, "JPY"), options: .init(decimalSeparator: .always)) == "¥1,234.")
    }

    @Test("A fixed precision far beyond the currency's scale pads with zeros instead of overflowing")
    func fixedPrecisionFarBeyondScalePadsWithoutOverflowing() throws {
        // 19 is the highest fraction length the Foundation integration ever asks this engine for
        // (`MoneyOf+FormatStyle.fractionLength(of:)`), and previously overflowed for any amount.
        let length = try #require(FractionLength(exactly: 19))
        let padding = String(repeating: "0", count: 19 - 2)

        #expect(
            Self.dollar.format(Self.money(1_00, "USD"), options: .init(precision: .fixed(length, rounding: .toNearestOrEven)))
                == "$1.00\(padding)"
        )
        #expect(
            Self.dollar.format(Self.money(-1_00, "USD"), options: .init(precision: .fixed(length, rounding: .toNearestOrEven)))
                == "-$1.00\(padding)"
        )
    }

    /// Returns options that show a fixed number of fraction digits.
    ///
    /// - Parameters:
    ///   - digits: The number of fraction digits to show.
    ///   - rounding: The rule for digits past `digits`.
    /// - Returns: The options.
    /// - Throws: An issue if `digits` is not a valid fraction length.
    static func fixed(_ digits: Int, _ rounding: RoundingRule) throws -> MoneyFormatOptions {
        let length = try #require(FractionLength(exactly: digits))
        return MoneyFormatOptions(precision: .fixed(length, rounding: rounding))
    }

    @Test("The largest amount pads past one 64-bit word")
    func largestAmountPads() throws {
        let largest = Self.money(.max, "USD")

        #expect(Self.dollar.format(largest, options: try Self.fixed(4, .toNearestOrEven)) == "$92,233,720,368,547,758.0700")
        #expect(
            Self.dollar.format(largest, options: try Self.fixed(19, .toNearestOrEven))
                == "$92,233,720,368,547,758.0700000000000000000"
        )
    }

    @Test("The smallest amount pads past one 64-bit word")
    func smallestAmountPads() throws {
        let smallest = Self.money(.min, "USD")

        #expect(Self.dollar.format(smallest, options: try Self.fixed(4, .toNearestOrEven)) == "-$92,233,720,368,547,758.0800")
        #expect(
            Self.dollar.format(smallest, options: try Self.fixed(19, .toNearestOrEven))
                == "-$92,233,720,368,547,758.0800000000000000000"
        )
    }

    @Test("The extreme amounts round to whole units")
    func extremeAmountsRoundToWholeUnits() throws {
        #expect(Self.dollar.format(Self.money(.max, "USD"), options: try Self.fixed(0, .toNearestOrEven)) == "$92,233,720,368,547,758")
        #expect(Self.dollar.format(Self.money(.max, "USD"), options: try Self.fixed(0, .up)) == "$92,233,720,368,547,759")
        #expect(Self.dollar.format(Self.money(.min, "USD"), options: try Self.fixed(0, .down)) == "-$92,233,720,368,547,759")
    }

    @Test("A negative amount that rounds to zero shows no minus sign")
    func negativeRoundingToZeroHasNoMinus() throws {
        #expect(Self.dollar.format(Self.money(-1, "USD"), options: try Self.fixed(0, .toNearestOrEven)) == "$0")
        #expect(Self.dollar.format(Self.money(-50, "USD"), options: try Self.fixed(0, .toNearestOrEven)) == "$0")
        #expect(Self.dollar.format(Self.money(-1, "USD"), options: try Self.fixed(1, .towardZero)) == "$0.0")
    }
}
