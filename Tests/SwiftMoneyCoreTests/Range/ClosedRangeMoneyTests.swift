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
