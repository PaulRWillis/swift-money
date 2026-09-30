import SwiftMoneyCore
import Testing

@Suite("Range of typed amounts")
struct RangeMoneyTests {

    @Test("Ordered bounds build the range ..< builds")
    func orderedBounds() throws {
        let range = try Range(checkedBounds: (lower: GBP(minorUnits: 10_00), upper: GBP(minorUnits: 250_00)))

        #expect(range == GBP(minorUnits: 10_00) ..< GBP(minorUnits: 250_00))
    }

    @Test("Equal bounds build an empty range")
    func equalBounds() throws {
        let range = try Range(checkedBounds: (lower: JPY(minorUnits: 5), upper: JPY(minorUnits: 5)))

        #expect(range.isEmpty)
    }

    @Test("Inverted bounds throw only InvertedBoundsError, so a catch needs no mismatch branch")
    func invertedThrowsExactly() {
        do throws(InvertedBoundsError<Currencies.GBP>) {
            _ = try Range(checkedBounds: (lower: GBP(minorUnits: 250_00), upper: GBP(minorUnits: 10_00)))
            Issue.record("Expected inverted bounds to throw")
        } catch {
            #expect(error.lowerBound == GBP(minorUnits: 250_00))
            #expect(error.upperBound == GBP(minorUnits: 10_00))
        }
    }

    @Test("A runtime range in the bounds' currency becomes a typed range")
    func fromRuntime() throws {
        let runtime = try Money(minorUnits: 10_00, currency: .gbp)..<Money(minorUnits: 250_00, currency: .gbp)

        #expect(try Range<GBP>(runtime) == GBP(minorUnits: 10_00) ..< GBP(minorUnits: 250_00))
    }

    @Test("A runtime range in another currency throws a mismatch, the bounds' currency first")
    func fromRuntimeMismatch() throws {
        let euros = try Money(minorUnits: 10_00, currency: .eur)..<Money(minorUnits: 250_00, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try Range<GBP>(euros)
        }
    }

    @Test("A typed range survives a round trip through a runtime one")
    func runtimeRoundTrip() throws {
        let typed = JPY(minorUnits: -5) ..< JPY(minorUnits: 5)

        #expect(try Range<JPY>(MoneyRange(typed)) == typed)
    }

    @Test("Inverted bounds in yen report both bounds")
    func invertedYen() {
        #expect(throws: InvertedBoundsError<Currencies.JPY>.self) {
            try Range(checkedBounds: (lower: JPY(minorUnits: 2), upper: JPY(minorUnits: 1)))
        }
    }
}
