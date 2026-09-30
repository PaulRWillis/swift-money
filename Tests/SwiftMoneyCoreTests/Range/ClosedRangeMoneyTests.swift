import SwiftMoneyCore
import Testing

@Suite("ClosedRange of typed amounts")
struct ClosedRangeMoneyTests {

    @Test("Ordered bounds build the range ... builds")
    func orderedBounds() throws {
        let range = try ClosedRange(checkedBounds: (lower: GBP(minorUnits: 10_00), upper: GBP(minorUnits: 250_00)))

        #expect(range == GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00))
    }

    @Test("Equal bounds build a range holding that one amount")
    func equalBounds() throws {
        let range = try ClosedRange(checkedBounds: (lower: JPY(minorUnits: 5), upper: JPY(minorUnits: 5)))

        #expect(range.contains(JPY(minorUnits: 5)))
    }

    @Test("Inverted bounds throw only InvertedBoundsError, so a catch needs no mismatch branch")
    func invertedThrowsExactly() {
        do throws(InvertedBoundsError<Currencies.GBP>) {
            _ = try ClosedRange(checkedBounds: (lower: GBP(minorUnits: 250_00), upper: GBP(minorUnits: 10_00)))
            Issue.record("Expected inverted bounds to throw")
        } catch {
            #expect(error.lowerBound == GBP(minorUnits: 250_00))
            #expect(error.upperBound == GBP(minorUnits: 10_00))
        }
    }

    @Test("A runtime range in the bounds' currency becomes a typed range")
    func fromRuntime() throws {
        let runtime = try Money(minorUnits: 10_00, currency: .gbp)...Money(minorUnits: 250_00, currency: .gbp)

        #expect(try ClosedRange<GBP>(runtime) == GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00))
    }

    @Test("A runtime range in another currency throws a mismatch, the bounds' currency first")
    func fromRuntimeMismatch() throws {
        let yen = try Money(minorUnits: 10, currency: .jpy)...Money(minorUnits: 250, currency: .jpy)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .jpy)) {
            try ClosedRange<GBP>(yen)
        }
    }

    @Test("A typed range survives a round trip through a runtime one")
    func runtimeRoundTrip() throws {
        let typed = JPY(minorUnits: -5) ... JPY(minorUnits: 5)

        #expect(try ClosedRange<JPY>(ClosedMoneyRange(typed)) == typed)
    }

    @Test("A half-open range becomes the closed range ending one minor unit lower")
    func fromHalfOpen() {
        #expect(ClosedRange(GBP(minorUnits: 1_00) ..< GBP(minorUnits: 2_00)) == GBP(minorUnits: 1_00) ... GBP(minorUnits: 1_99))
        #expect(ClosedRange(JPY.min ..< JPY.max) == JPY.min ... JPY(minorUnits: Int64.max - 1))
    }

    @Test("An empty half-open range has no closed equivalent")
    func fromEmptyHalfOpen() {
        #expect(ClosedRange(GBP(minorUnits: 1_00) ..< GBP(minorUnits: 1_00)) == nil)
    }

    @Test("A custom currency builds and refuses in the same way")
    func customScale() {
        typealias Credits = MoneyOf<Millicredits>

        #expect(throws: InvertedBoundsError<Millicredits>.self) {
            try ClosedRange(checkedBounds: (lower: Credits(minorUnits: 2), upper: Credits(minorUnits: 1)))
        }
        #expect(throws: Never.self) {
            try ClosedRange(checkedBounds: (lower: Credits(minorUnits: 1), upper: Credits(minorUnits: 2)))
        }
    }
}
