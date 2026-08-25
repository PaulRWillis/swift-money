import SwiftMoney
import Testing

private let amounts = [-1000, -101, -12, -3, -1, 0, 1, 3, 12, 101, 1000]

private let weightLists: [[Int]] = [
    [1],
    [1, 1, 1],
    [60, 30, 10],
    [3, 2, 1],
    [0, 1],
    [7, 11, 13, 17],
]

@Suite("Weighted Split Tests")
struct WeightedSplitTests {

    @Test("Parts always sum to the original amount", arguments: amounts, weightLists)
    func partsSumToOriginalAmount(amount: Int, weightList: [Int]) throws {
        let weights = try #require(Weights(exactly: weightList))
        let money = GBP(minorUnits: amount)

        let parts = money.split(by: weights)

        #expect(parts.reduce(GBP.zero, +) == money)
    }

    @Test("One part per weight", arguments: amounts, weightLists)
    func onePartPerWeight(amount: Int, weightList: [Int]) throws {
        let weights = try #require(Weights(exactly: weightList))

        let parts = GBP(minorUnits: amount).split(by: weights)

        #expect(parts.count == weightList.count)
    }

    // Exact shares are 2.33 and 4.67, so the leftover unit belongs to the second part. PoEAA's
    // printed allocate hands it to the first part instead, giving [3, 4]; this library deviates
    // deliberately, because [2, 5] sits closer to the exact proportions.
    @Test("Leftover minor units go to the largest remainders")
    func leftoverGoesToLargestRemainder() {
        let parts = GBP(minorUnits: 7).split(by: [1, 2])

        #expect(parts == [GBP(minorUnits: 2), GBP(minorUnits: 5)])
    }

    // Exact shares are 10.1, 30.3 and 60.6: one leftover unit, and the last remainder is largest.
    @Test("A later part with the largest remainder wins the leftover unit")
    func laterLargestRemainderWins() {
        let parts = GBP(minorUnits: 101).split(by: [10, 30, 60])

        #expect(parts == [GBP(minorUnits: 10), GBP(minorUnits: 30), GBP(minorUnits: 61)])
    }

    @Test("Weights that divide exactly give each part its exact share")
    func exactShares() {
        let parts = GBP(minorUnits: 100).split(by: [60, 30, 10])

        #expect(parts == [GBP(minorUnits: 60), GBP(minorUnits: 30), GBP(minorUnits: 10)])
    }

    @Test("Part order follows weight order")
    func partOrderFollowsWeightOrder() {
        let parts = GBP(minorUnits: 100).split(by: [10, 30, 60])

        #expect(parts == [GBP(minorUnits: 10), GBP(minorUnits: 30), GBP(minorUnits: 60)])
    }

    @Test("A zero amount gives every part zero")
    func zeroAmount() {
        let parts = GBP(minorUnits: 0).split(by: [60, 30, 10])

        #expect(parts == [GBP(minorUnits: 0), GBP(minorUnits: 0), GBP(minorUnits: 0)])
    }

    @Test("A single weight receives the whole amount")
    func singleWeight() {
        #expect(GBP(minorUnits: 4_99).split(by: [7]) == [GBP(minorUnits: 4_99)])
    }
}
