import CLDRCurrencyPatterns
import Testing

// Reading the grouping out of a CLDR pattern, the Indian system being the case that makes it awkward.
@Suite("Group Sizes Tests")
struct GroupSizesTests {

    @Test("Even grouping reads the same size twice")
    func evenGrouping() {
        #expect(GroupSizes(pattern: "¤#,##0.00") == GroupSizes(primary: 3, secondary: 3))
    }

    @Test("Indian grouping reads three then twos")
    func indianGrouping() {
        #expect(GroupSizes(pattern: "¤#,##,##0.00") == GroupSizes(primary: 3, secondary: 2))
    }

    // Pinned because it is a reading rather than a decision, and an unreachable one.
    @Test("A pattern with no separator reads its digits as a single group")
    func ungrouped() {
        #expect(GroupSizes(pattern: "¤#0.00") == GroupSizes(primary: 2, secondary: 2))
    }

    @Test("The fraction digits are not counted as a group")
    func fractionIsNotAGroup() {
        #expect(GroupSizes(pattern: "#,##0.000\u{00A0}¤") == GroupSizes(primary: 3, secondary: 3))
    }

    @Test("Only the positive subpattern is read")
    func ignoresTheNegativeSubpattern() {
        #expect(GroupSizes(pattern: "¤#,##,##0.00;(¤#0.00)") == GroupSizes(primary: 3, secondary: 2))
    }
}
