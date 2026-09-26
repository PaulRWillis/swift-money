import SwiftMoneyCore
import Testing

@Suite("MinGroupingDigits")
struct MinGroupingDigitsTests {

    @Test("A value of one or more is accepted", arguments: [1, 2, 3])
    func acceptsPositive(_ value: Int) throws {
        let threshold = try #require(MinGroupingDigits(exactly: value))
        #expect(threshold == MinGroupingDigits(integerLiteral: value))
    }

    @Test("A value below one is rejected")
    func rejectsBelowOne() {
        #expect(MinGroupingDigits(exactly: 0) == nil)
        #expect(MinGroupingDigits(exactly: -1) == nil)
    }
}
