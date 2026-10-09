import CLDRLocaleIdentifiers
import Testing

@Suite("LocaleLookupOrder")
struct LocaleLookupOrderTests {

    @Test("Names sort with ASCII letters compared as small letters")
    func sortsByFoldedBytes() {
        #expect(["en-SI", "en-Shaw", "en"].sorted(by: LocaleLookupOrder.precedes) == ["en", "en-Shaw", "en-SI"])
    }

    @Test("Names in order have no pair out of order")
    func sortedNamesPass() {
        #expect(LocaleLookupOrder.firstPairOutOfOrder(in: ["en", "en-GB", "en-Shaw", "en-SI"]) == nil)
    }

    // The runtime can't tell these apart, so filing both would make the search return either row.
    @Test("Two names differing only in letter case are a pair out of order")
    func caseTwinsFail() {
        let pair = LocaleLookupOrder.firstPairOutOfOrder(in: ["en", "en-gb", "en-GB"])

        #expect(pair?.earlier == "en-gb")
        #expect(pair?.later == "en-GB")
    }

    @Test("A name before one it follows is a pair out of order")
    func reversedNamesFail() {
        let pair = LocaleLookupOrder.firstPairOutOfOrder(in: ["en-SI", "en-Shaw"])

        #expect(pair?.earlier == "en-SI")
        #expect(pair?.later == "en-Shaw")
    }
}
