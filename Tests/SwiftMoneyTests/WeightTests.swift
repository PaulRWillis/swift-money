import SwiftMoney
import Testing

@Suite("Weight Tests")
struct WeightTests {

    @Test("A non-negative value is a valid weight")
    func nonNegativeIsValid() {
        #expect(Weight(exactly: 0) != nil)
        #expect(Weight(exactly: 1) != nil)
        #expect(Weight(exactly: Int.max) != nil)
    }

    @Test("A negative value is not a valid weight")
    func negativeIsNil() {
        #expect(Weight(exactly: -1) == nil)
        #expect(Weight(exactly: Int.min) == nil)
    }

    @Test("A weight reads back as its value")
    func readsBack() throws {
        let weight = try #require(Weight(exactly: 60))

        #expect(Int(weight) == 60)
    }

    @Test("A non-negative literal builds a weight")
    func nonNegativeLiteral() async {
        await #expect(processExitsWith: .success) {
            _ = 60 as Weight
        }
    }

    @Test("A negative literal traps")
    func negativeLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(-1 as Weight)
        }
    }

    @Test("Equal weights are equal")
    func equality() throws {
        #expect(try #require(Weight(exactly: 5)) == 5)
        #expect(Weight(exactly: 5) != Weight(exactly: 6))
    }
}
