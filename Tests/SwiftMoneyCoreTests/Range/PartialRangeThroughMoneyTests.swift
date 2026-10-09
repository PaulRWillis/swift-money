import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

@Suite("PartialRangeThrough of typed amounts")
struct PartialRangeThroughMoneyTests {

    @Test("A runtime range in the bound's currency becomes a typed range with the same bound")
    func fromRuntime() throws {
        let typed = try PartialRangeThrough<JPY>(...Money(minorUnits: 250, currency: .jpy))

        #expect(typed.upperBound == JPY(minorUnits: 250))
    }

    @Test("Bounds at the extremes of Int64 convert both ways unchanged")
    func extremes() throws {
        let lowest = Money(minorUnits: Int64.min, currency: .jpy)
        let highest = Money(minorUnits: Int64.max, currency: .jpy)

        #expect(try PartialRangeThrough<JPY>(...lowest).upperBound == JPY(minorUnits: Int64.min))
        #expect(try PartialRangeThrough<JPY>(...highest).upperBound == JPY(minorUnits: Int64.max))
        #expect(PartialMoneyRangeThrough(...JPY(minorUnits: Int64.min)) == ...lowest)
        #expect(PartialMoneyRangeThrough(...JPY(minorUnits: Int64.max)) == ...highest)
    }

    @Test("A runtime range in a currency with another scale throws a mismatch, the bound's currency first")
    func fromRuntimeMismatch() {
        let coarse = customCurrency(code: "MCR", unitScale: 1)

        #expect(throws: MoneyError.currencyMismatch(lhs: Millicredits.currency, rhs: coarse)) {
            try PartialRangeThrough<MoneyOf<Millicredits>>(...Money(minorUnits: 250, currency: coarse))
        }
    }
}
