import SwiftMoneyCore
import Testing

private let amounts = [-1000, -101, -12, -3, -1, 0, 1, 3, 12, 101, 1000]

private let weightLists: [[Weight]] = [
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
    func partsSumToOriginalAmount(amount: Int, weightList: [Weight]) throws {
        let weights = try #require(Weights(weightList))
        let money = GBP(minorUnits: amount)

        let distribution = money.split(by: weights)

        #expect(distribution.amounts.reduce(GBP.zero, +) == money)
    }

    @Test("One part per weight, in weight order", arguments: amounts, weightLists)
    func onePartPerWeight(amount: Int, weightList: [Weight]) throws {
        let weights = try #require(Weights(weightList))

        let distribution = GBP(minorUnits: amount).split(by: weights)

        #expect(distribution.count == weightList.count)
        #expect(distribution.weights == weightList)
    }

    @Test("Each part pairs its weight with its share")
    func partPairsWeightAndShare() {
        let parts = GBP(minorUnits: 100).split(by: [60, 30, 10]).parts

        #expect(parts.map(\.weight) == [60, 30, 10])
        #expect(parts.map(\.amount) == [GBP(minorUnits: 60), GBP(minorUnits: 30), GBP(minorUnits: 10)])
    }

    // Exact shares are 2.33 and 4.67, so the leftover unit belongs to the second part. PoEAA's
    // printed allocate hands it to the first part instead, giving [3, 4]; this library deviates
    // deliberately, because [2, 5] sits closer to the exact proportions.
    @Test("Leftover minor units go to the largest remainders")
    func leftoverGoesToLargestRemainder() {
        let amounts = GBP(minorUnits: 7).split(by: [1, 2]).amounts

        #expect(amounts == [GBP(minorUnits: 2), GBP(minorUnits: 5)])
    }

    // Exact shares are 10.1, 30.3 and 60.6: one leftover unit, and the last remainder is largest.
    @Test("A later part with the largest remainder wins the leftover unit")
    func laterLargestRemainderWins() {
        let amounts = GBP(minorUnits: 101).split(by: [10, 30, 60]).amounts

        #expect(amounts == [GBP(minorUnits: 10), GBP(minorUnits: 30), GBP(minorUnits: 61)])
    }

    @Test("Weights that divide exactly give each part its exact share")
    func exactShares() {
        let amounts = GBP(minorUnits: 100).split(by: [60, 30, 10]).amounts

        #expect(amounts == [GBP(minorUnits: 60), GBP(minorUnits: 30), GBP(minorUnits: 10)])
    }

    @Test("Part order follows weight order")
    func partOrderFollowsWeightOrder() {
        let amounts = GBP(minorUnits: 100).split(by: [10, 30, 60]).amounts

        #expect(amounts == [GBP(minorUnits: 10), GBP(minorUnits: 30), GBP(minorUnits: 60)])
    }

    @Test("Equal remainders break toward the earliest part")
    func equalRemaindersBreakTowardEarliestPart() {
        let amounts = GBP(minorUnits: 100).split(by: [1, 1, 1]).amounts

        #expect(amounts == [GBP(minorUnits: 34), GBP(minorUnits: 33), GBP(minorUnits: 33)])
    }

    @Test("Equal weights match an even split", arguments: amounts, 1...6)
    func equalWeightsMatchEvenSplit(amount: Int, count: Int) throws {
        let weights = try #require(Weights(Array(repeating: Weight(integerLiteral: 1), count: count)))
        let parts = try #require(PartCount(exactly: count))
        let money = GBP(minorUnits: amount)

        #expect(money.split(by: weights).amounts == Array(money.split(into: parts).amounts))
    }

    // The leftover unit goes to a part with a non-zero remainder, never to the zero weight.
    @Test("A zero weight receives exactly zero")
    func zeroWeightReceivesZero() {
        let amounts = GBP(minorUnits: 101).split(by: [0, 1, 1]).amounts

        #expect(amounts == [GBP(minorUnits: 0), GBP(minorUnits: 51), GBP(minorUnits: 50)])
    }

    @Test("A zero amount gives every part zero")
    func zeroAmount() {
        let amounts = GBP(minorUnits: 0).split(by: [60, 30, 10]).amounts

        #expect(amounts == [GBP(minorUnits: 0), GBP(minorUnits: 0), GBP(minorUnits: 0)])
    }

    @Test("A single weight receives the whole amount")
    func singleWeight() {
        #expect(GBP(minorUnits: 4_99).split(by: [7]).amounts == [GBP(minorUnits: 4_99)])
    }

    // Splitting a refund: the leftover unit enlarges a part's magnitude, and equal remainders
    // still break toward the earliest part, matching split(into:)'s convention.
    @Test("A negative amount mirrors the positive split by magnitude")
    func negativeAmountMirrorsByMagnitude() {
        let amounts = GBP(minorUnits: -10).split(by: [1, 1, 1]).amounts

        #expect(amounts == [GBP(minorUnits: -4), GBP(minorUnits: -3), GBP(minorUnits: -3)])
    }

    @Test("A negative amount sends the leftover unit to the largest remainder")
    func negativeLeftoverGoesToLargestRemainder() {
        let amounts = GBP(minorUnits: -7).split(by: [1, 2]).amounts

        #expect(amounts == [GBP(minorUnits: -2), GBP(minorUnits: -5)])
    }

    // A naive amount-times-weight product overflows on the first weight, so this pins the
    // full-width path: weighted splitting never traps.
    @Test("The largest amount splits without overflow")
    func largestAmountSplits() {
        let amounts = GBP.max.split(by: [2, 1]).amounts

        #expect(amounts.reduce(GBP.zero, +) == GBP.max)
        #expect(amounts == [
            GBP(minorUnits: 6_148_914_691_236_517_205),
            GBP(minorUnits: 3_074_457_345_618_258_602),
        ])
    }

    @Test("The smallest amount splits without overflow")
    func smallestAmountSplits() {
        let amounts = GBP.min.split(by: [1, 1, 1]).amounts

        #expect(amounts.reduce(GBP.zero, +) == GBP.min)
        #expect(amounts == [
            GBP(minorUnits: -3_074_457_345_618_258_603),
            GBP(minorUnits: -3_074_457_345_618_258_603),
            GBP(minorUnits: -3_074_457_345_618_258_602),
        ])
    }

    @Test("A runtime-currency amount splits and keeps its currency")
    func runtimeCurrencySplits() {
        let money = Money(minorUnits: 100, currency: .gbp)

        let amounts = money.split(by: [1, 1, 1]).amounts

        #expect(amounts == [
            Money(minorUnits: 34, currency: .gbp),
            Money(minorUnits: 33, currency: .gbp),
            Money(minorUnits: 33, currency: .gbp),
        ])
    }
}
