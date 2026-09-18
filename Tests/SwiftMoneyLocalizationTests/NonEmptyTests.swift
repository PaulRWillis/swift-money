import SwiftMoneyLocalization
import Testing

@Suite("NonEmpty")
struct NonEmptyTests {

    @Test("An empty array has no non-empty counterpart")
    func emptyArrayIsRejected() {
        #expect(NonEmpty<Int>([]) == nil)
    }

    @Test("A non-empty array keeps every element, in order")
    func arrayKeepsEveryElementInOrder() throws {
        let values = try #require(NonEmpty([3, 1, 2]))

        #expect(Array(values) == [3, 1, 2])
    }

    @Test("A single element iterates once")
    func singleElementIteratesOnce() {
        #expect(Array(NonEmpty(7)) == [7])
    }

    @Test("The first element is available without unwrapping")
    func firstElementIsNotOptional() {
        let values = NonEmpty(3, [1, 2])

        #expect(values.first == 3)
    }

    @Test("Two non-empty sequences are equal when their elements match")
    func equalElementsAreEqual() {
        #expect(NonEmpty(1, [2]) == NonEmpty([1, 2]))
        #expect(NonEmpty(1, [2]) != NonEmpty([2, 1]))
    }
}
