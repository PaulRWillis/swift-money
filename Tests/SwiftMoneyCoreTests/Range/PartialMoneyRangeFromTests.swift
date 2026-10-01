import SwiftMoneyCore
import Testing

@Suite("PartialMoneyRangeFrom")
struct PartialMoneyRangeFromTests {

    private let minimum = Money(minorUnits: 10_00, currency: .gbp)

    @Test("Builds with the postfix ... operator, without try")
    func buildsWithoutTry() {
        let range = minimum...

        #expect(range == PartialMoneyRangeFrom(minimum))
        #expect(range.lowerBound == minimum)
    }

    @Test("Contains its bound and what lies above it")
    func includesBound() throws {
        let range = minimum...

        #expect(try range.contains(minimum))
        #expect(try range.contains(Money(minorUnits: 10_01, currency: .gbp)))
        #expect(try range.contains(Money(minorUnits: 9_99, currency: .gbp)) == false)
    }

    @Test("Asking about an amount in another currency throws a mismatch, bound's currency first")
    func mismatch() {
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try (minimum...).contains(Money(minorUnits: 10_00, currency: .eur))
        }
    }

    @Test("A typed range becomes a runtime range with the same bound, in the type's currency")
    func fromTyped() {
        #expect(PartialMoneyRangeFrom(GBP(minorUnits: 10_00)...) == minimum...)
    }

    @Test("Equal ranges hash equally; the same bound in another currency is unequal")
    func hashAndEquality() {
        let euros = Money(minorUnits: 10_00, currency: .eur)

        #expect((minimum...).hashValue == PartialMoneyRangeFrom(minimum).hashValue)
        #expect(minimum... != euros...)
    }
}
