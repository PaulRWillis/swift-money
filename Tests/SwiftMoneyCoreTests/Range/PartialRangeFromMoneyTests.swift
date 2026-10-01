import SwiftMoneyCore
import Testing

@Suite("PartialRangeFrom of typed amounts")
struct PartialRangeFromMoneyTests {

    @Test("A runtime range in the bound's currency becomes a typed range with the same bound")
    func fromRuntime() throws {
        let typed = try PartialRangeFrom<GBP>(Money(minorUnits: 10_00, currency: .gbp)...)

        #expect(typed.lowerBound == GBP(minorUnits: 10_00))
    }

    @Test("Bounds at the extremes of Int64 convert both ways unchanged")
    func extremes() throws {
        let lowest = Money(minorUnits: Int64.min, currency: .gbp)
        let highest = Money(minorUnits: Int64.max, currency: .gbp)

        #expect(try PartialRangeFrom<GBP>(lowest...).lowerBound == GBP(minorUnits: Int64.min))
        #expect(try PartialRangeFrom<GBP>(highest...).lowerBound == GBP(minorUnits: Int64.max))
        #expect(PartialMoneyRangeFrom(GBP(minorUnits: Int64.min)...) == lowest...)
        #expect(PartialMoneyRangeFrom(GBP(minorUnits: Int64.max)...) == highest...)
    }

    @Test("A runtime range in another currency throws a mismatch, the bound's currency first")
    func fromRuntimeMismatch() {
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .jpy)) {
            try PartialRangeFrom<GBP>(Money(minorUnits: 10, currency: .jpy)...)
        }
    }
}
