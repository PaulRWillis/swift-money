import SwiftMoneyFoundation
import Testing

@Suite("Rounding Increment Tests")
struct RoundingIncrementTests {
    // MARK: - Exact Initialization

    @Test("A value of one creates an increment")
    func acceptsOne() throws {
        let increment = try #require(RoundingIncrement(exactly: 1))

        #expect(Int64(increment) == 1)
    }

    @Test("A value above one creates an increment")
    func acceptsFive() throws {
        let increment = try #require(RoundingIncrement(exactly: 5))

        #expect(Int64(increment) == 5)
    }

    @Test("Zero is refused")
    func refusesZero() {
        #expect(RoundingIncrement(exactly: 0) == nil)
    }

    @Test("A negative value is refused")
    func refusesNegative() {
        #expect(RoundingIncrement(exactly: -5) == nil)
    }

    // MARK: - Conversion

    @Test("An increment converts back to the integer it was built from")
    func convertsToInt64() throws {
        let increment = try #require(RoundingIncrement(exactly: 25))

        #expect(Int64(increment) == 25)
    }
}
