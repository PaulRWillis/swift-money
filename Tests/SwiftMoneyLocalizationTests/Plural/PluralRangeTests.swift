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
    func rangeContainsBoundsAndInterior() {
        let range = PluralRange(2 ... 4)

        #expect(range.contains(2))
        #expect(range.contains(3))
        #expect(range.contains(4))
        #expect(!range.contains(1))
        #expect(!range.contains(5))
    }

    @Test("A range of one value is the same as that value's range")
    func singleValueBoundsMatch() {
        #expect(PluralRange(7 ... 7) == PluralRange(7))
    }

    @Test("A range reports the span it covers")
    func rangeReportsItsBounds() {
        #expect(PluralRange(2 ... 4).bounds == 2 ... 4)
    }
}
