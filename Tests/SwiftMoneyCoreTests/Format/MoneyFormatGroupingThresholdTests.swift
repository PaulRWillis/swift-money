import SwiftMoneyCore
import Testing

// A `minGroupingDigits` above one delays grouping until the integer part is long enough, as Slovenian
// does; the default of one groups as soon as there is more than one group, unchanged from before.
@Suite("MoneyFormat grouping threshold")
struct MoneyFormatGroupingThresholdTests {

    static func money(_ minorUnits: Int64, _ iso: CurrencyCode) -> Money {
        guard let currency = Currency(iso: iso) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return Money(minorUnits: minorUnits, currency: currency)
    }

    static func dollar(minGroupingDigits: MinGroupingDigits) -> MoneyFormat {
        MoneyFormat(
            symbol: "$",
            pattern: MoneyFormatTests.pattern(currencyFirst: true),
            grouping: .repeating(3, separator: ",", minGroupingDigits: minGroupingDigits)
        )
    }

    @Test("A threshold of two leaves a four-digit integer ungrouped but groups a five-digit one")
    func delaysGrouping() {
        let delayed = Self.dollar(minGroupingDigits: 2)
        #expect(delayed.format(Self.money(1_234_00, "USD")) == "$1234.00")
        #expect(delayed.format(Self.money(12_345_00, "USD")) == "$12,345.00")
    }

    @Test("The default threshold of one groups a four-digit integer, as before")
    func defaultGroupsFromFourDigits() {
        let normal = Self.dollar(minGroupingDigits: 1)
        #expect(normal.format(Self.money(1_234_00, "USD")) == "$1,234.00")
    }

    @Test("A threshold of two also delays grouping in the run seam")
    func delaysGroupingInRuns() {
        let delayed = Self.dollar(minGroupingDigits: 2)
        let short = delayed.runs(Self.money(1_234_00, "USD"), options: MoneyFormatOptions())
            .map(\.text).joined()
        #expect(short == "$1234.00")

        let long = delayed.runs(Self.money(12_345_00, "USD"), options: MoneyFormatOptions())
            .map(\.text).joined()
        #expect(long == "$12,345.00")
    }
}
