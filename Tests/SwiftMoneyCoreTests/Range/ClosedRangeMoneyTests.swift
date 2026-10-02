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

    @Test("Inverted bounds throw invertedBounds, and a switch over the error needs no mismatch case")
    func invertedThrowsExactly() {
        do throws(MoneyRangeParsingError<Currencies.GBP>) {
            _ = try ClosedRange(checkedBounds: (lower: GBP(minorUnits: 250_00), upper: GBP(minorUnits: 10_00)))
            Issue.record("Expected inverted bounds to throw")
        } catch {
            switch error {
            case let .invertedBounds(lowerBound, upperBound):
                #expect(lowerBound == GBP(minorUnits: 250_00))
                #expect(upperBound == GBP(minorUnits: 10_00))
            }
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

    @Test("Bounds at the extremes of Int64 build, and survive a round trip through a runtime range")
    func int64Extremes() throws {
        let typed = try ClosedRange(checkedBounds: (lower: GBP.min, upper: GBP.max))

        #expect(typed == GBP.min ... GBP.max)
        #expect(try ClosedRange<GBP>(ClosedMoneyRange(typed)) == typed)
    }

    @Test("A custom currency builds and refuses in the same way, with no mismatch case to switch on")
    func customScale() {
        typealias Credits = MoneyOf<Millicredits>

        do throws(MoneyRangeParsingError<Millicredits>) {
            _ = try ClosedRange(checkedBounds: (lower: Credits(minorUnits: 2), upper: Credits(minorUnits: 1)))
            Issue.record("Expected inverted bounds to throw")
        } catch {
            switch error {
            case let .invertedBounds(lowerBound, upperBound):
                #expect(lowerBound == Credits(minorUnits: 2))
                #expect(upperBound == Credits(minorUnits: 1))
            }
        }
        #expect(throws: Never.self) {
            try ClosedRange(checkedBounds: (lower: Credits(minorUnits: 1), upper: Credits(minorUnits: 2)))
        }
    }
}
