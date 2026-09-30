import SwiftMoneyCore
import Testing

@Suite("PartialMoneyRangeThrough")
struct PartialMoneyRangeThroughTests {

    private let limit = Money(minorUnits: 250, currency: .jpy)

    @Test("Builds with the prefix ... operator, without try")
    func buildsWithoutTry() {
        let range = ...limit

        #expect(range == PartialMoneyRangeThrough(limit))
        #expect(range.upperBound == limit)
    }

    @Test("Contains its bound and what lies below it")
    func includesBound() throws {
        let range = ...limit

        #expect(try range.contains(limit))
        #expect(try range.contains(Money(minorUnits: 249, currency: .jpy)))
        #expect(try range.contains(Money(minorUnits: 251, currency: .jpy)) == false)
    }

    @Test("Asking about an amount in another currency throws a mismatch, bound's currency first")
    func mismatch() {
        #expect(throws: MoneyError.currencyMismatch(lhs: .jpy, rhs: .gbp)) {
            try (...limit).contains(Money(minorUnits: 1, currency: .gbp))
        }
    }

    @Test("Equal ranges hash equally; the same bound in another currency is unequal")
    func hashAndEquality() {
        let coarse = Money(minorUnits: 250, currency: customCurrency(code: "MCR", unitScale: 1))
        let fine = Money(minorUnits: 250, currency: Millicredits.currency)

        #expect((...limit).hashValue == PartialMoneyRangeThrough(limit).hashValue)
        #expect(...coarse != ...fine)
    }
}
