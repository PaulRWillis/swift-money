import SwiftMoneyCore
import Testing

@Suite("PartialMoneyRangeUpTo")
struct PartialMoneyRangeUpToTests {

    private let limit = Money(minorUnits: 250_00, currency: .gbp)

    @Test("Builds with the prefix ..< operator, without try")
    func buildsWithoutTry() {
        let range = ..<limit

        #expect(range == PartialMoneyRangeUpTo(limit))
        #expect(range.upperBound == limit)
    }

    @Test("Contains what lies below its bound, but not the bound itself")
    func excludesBound() throws {
        let range = ..<limit

        #expect(try range.contains(Money(minorUnits: 249_99, currency: .gbp)))
        #expect(try range.contains(Money(minorUnits: -1_00, currency: .gbp)))
        #expect(try range.contains(limit) == false)
        #expect(try range.contains(Money(minorUnits: 250_01, currency: .gbp)) == false)
    }

    @Test("Asking about an amount in another currency throws a mismatch, bound's currency first")
    func mismatch() {
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .jpy)) {
            try (..<limit).contains(Money(minorUnits: 1, currency: .jpy))
        }
    }

    @Test("Its currency is its bound's currency")
    func currency() {
        #expect((..<limit).currency == .gbp)
        #expect((..<Money(minorUnits: 1, currency: Millicredits.currency)).currency == Millicredits.currency)
    }

    @Test("A typed range becomes a runtime range with the same bound, in the type's currency")
    func fromTyped() {
        #expect(PartialMoneyRangeUpTo(..<GBP(minorUnits: 250_00)) == ..<limit)
    }

    @Test("Equal ranges hash equally; the same bound in another currency is unequal")
    func hashAndEquality() {
        let euros = Money(minorUnits: 250_00, currency: .eur)

        #expect((..<limit).hashValue == PartialMoneyRangeUpTo(limit).hashValue)
        #expect(..<limit != ..<euros)
    }
}
