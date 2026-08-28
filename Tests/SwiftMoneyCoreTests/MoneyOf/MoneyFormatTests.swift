import SwiftMoneyCore
import Testing

// Foundation-free assembly checks for the format engine: grouping (uniform and Indian), symbol
// placement, spacing, sign, zero fraction, and accounting parentheses — pinned deterministically with
// hand-written descriptors. ICU parity is verified separately in the Foundation test target, where ICU
// is available.
@Suite("MoneyFormat engine assembly")
struct MoneyFormatTests {

    static let dollar = MoneyFormat(symbol: "$", placement: .before)

    static func money(_ minorUnits: Int64, _ iso: CurrencyCode) -> Money {
        guard let currency = Currency(iso: iso) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return Money(minorUnits: minorUnits, currency: currency)
    }

    @Test("Symbol placement, grouping, spacing, sign, zero fraction, accounting")
    func assembly() {
        let eurDE = MoneyFormat(
            symbol: "€", placement: .after, spacing: "\u{00A0}",
            decimalSeparator: ",", groupingSeparator: "."
        )
        let eurFR = MoneyFormat(
            symbol: "€", placement: .after, spacing: "\u{202F}",
            decimalSeparator: ",", groupingSeparator: "\u{202F}"
        )
        let jpy = MoneyFormat(symbol: "¥", placement: .before)
        let inr = MoneyFormat(symbol: "₹", placement: .before, primaryGroupingSize: 3, secondaryGroupingSize: 2)

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

        // Grouping off, and always-on separator on a whole amount.
        #expect(Self.dollar.format(Self.money(1_234_56, "USD"), options: .init(grouping: false)) == "$1234.56")
        #expect(jpy.format(Self.money(1_234, "JPY"), options: .init(decimalSeparator: .always)) == "¥1,234.")
    }
}
