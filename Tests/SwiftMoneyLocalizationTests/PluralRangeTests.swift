import SwiftMoneyLocalization
import Testing

@Suite("PluralRange Tests")
struct PluralRangeTests {

    @Test("A single value contains only itself")
    func singleValueContainsOnlyItself() {
        let range = PluralRange(1)

        #expect(range.contains(1))
        #expect(!range.contains(0))
        #expect(!range.contains(2))
    }

    @Test("A range contains its bounds and everything between them")
    func rangeContainsBoundsAndInterior() throws {
        let range = try #require(PluralRange(lowerBound: 2, upperBound: 4))

        #expect(range.contains(2))
        #expect(range.contains(3))
        #expect(range.contains(4))
        #expect(!range.contains(1))
        #expect(!range.contains(5))
    }

    @Test("A range whose bounds are equal holds that one value")
    func equalBoundsHoldOneValue() throws {
        let range = try #require(PluralRange(lowerBound: 7, upperBound: 7))

        #expect(range == PluralRange(7))
    }

    @Test("A range whose upper bound is below its lower bound is rejected")
    func descendingBoundsAreRejected() {
        #expect(PluralRange(lowerBound: 4, upperBound: 2) == nil)
    }
}
