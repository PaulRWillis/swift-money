import SwiftMoneyCore
import Testing

@Suite("PartialRangeUpTo of typed amounts")
struct PartialRangeUpToMoneyTests {

    @Test("A runtime range in the bound's currency becomes a typed range with the same bound")
    func fromRuntime() throws {
        let typed = try PartialRangeUpTo<GBP>(..<Money(minorUnits: 250_00, currency: .gbp))

        #expect(typed.upperBound == GBP(minorUnits: 250_00))
    }

    @Test("Bounds at the extremes of Int64 convert both ways unchanged")
    func extremes() throws {
        let lowest = Money(minorUnits: Int64.min, currency: .gbp)
        let highest = Money(minorUnits: Int64.max, currency: .gbp)

        #expect(try PartialRangeUpTo<GBP>(..<lowest).upperBound == GBP(minorUnits: Int64.min))
        #expect(try PartialRangeUpTo<GBP>(..<highest).upperBound == GBP(minorUnits: Int64.max))
        #expect(PartialMoneyRangeUpTo(..<GBP(minorUnits: Int64.min)) == ..<lowest)
        #expect(PartialMoneyRangeUpTo(..<GBP(minorUnits: Int64.max)) == ..<highest)
    }

    @Test("A runtime range in another currency throws a mismatch, the bound's currency first")
    func fromRuntimeMismatch() {
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try PartialRangeUpTo<GBP>(..<Money(minorUnits: 250_00, currency: .eur))
        }
    }
}
