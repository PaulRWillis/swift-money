import SwiftMoneyCore
import Testing

@Suite("PartialRangeThrough of typed amounts")
struct PartialRangeThroughMoneyTests {

    @Test("A runtime range in the bound's currency becomes a typed range with the same bound")
    func fromRuntime() throws {
        let typed = try PartialRangeThrough<JPY>(...Money(minorUnits: 250, currency: .jpy))

        #expect(typed.upperBound == JPY(minorUnits: 250))
    }

    @Test("A runtime range in a currency with another scale throws a mismatch, the bound's currency first")
    func fromRuntimeMismatch() {
        let coarse = customCurrency(code: "MCR", unitScale: 1)

        #expect(throws: MoneyError.currencyMismatch(lhs: Millicredits.currency, rhs: coarse)) {
            try PartialRangeThrough<MoneyOf<Millicredits>>(...Money(minorUnits: 250, currency: coarse))
        }
    }
}
