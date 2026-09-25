import SwiftMoneyCore
import Testing

// An amount and the weights it is split by. The source list is kept alongside the `Weights` value so the
// order property can compare the split's weights against exactly what went in.
private struct WeightedCase: Sendable {
    let money: GBP
    let weightValues: [Weight]
    let weights: Weights
}

// |minorUnits| ≤ 10⁹, at most 20 weights each ≤ 10³. The share bound multiplies `part × sum`
// (≤ 10⁹ × 2×10⁴ = 2×10¹³) and `whole × weight` (≤ 10⁹ × 10³ = 10¹²); both stay far below Int64.max
// (~9.2×10¹⁸).
private let weightedAmountBound: Int64 = 1_000_000_000
private let maxWeightCount: Int64 = 20
private let maxWeight: Int64 = 1_000

private func weightedCase(_ money: GBP, _ values: [Weight]) -> WeightedCase {
    // The generator's list is never empty and always has a positive weight, so `Weights.init` never
    // returns nil; `?? [1]` names that unreachable fallback without a force unwrap.
    WeightedCase(money: money, weightValues: values, weights: Weights(values) ?? [1])
}

private let weightedEdges: [WeightedCase] = [
    weightedCase(.zero, [1]),
    weightedCase(GBP(minorUnits: 1), [1, 1, 1]),
    weightedCase(GBP(minorUnits: 100), [60, 30, 10]),
    weightedCase(GBP(minorUnits: weightedAmountBound), [1, 0]),
    weightedCase(GBP(minorUnits: -weightedAmountBound), [7, 3]),
]

private let weightedCases: [WeightedCase] = samples(
    zip(
        .typedMoney(minorUnitsIn: -weightedAmountBound ... weightedAmountBound),
        Gen<[Weight]>.weightList(countIn: 1 ... maxWeightCount, weightIn: 0 ... maxWeight)
    ).map(weightedCase),
    seed: PropertySeed.weightedSplit,
    edges: weightedEdges
)

@Suite("Weighted split properties")
struct WeightedSplitPropertyTests {

    @Test("The parts sum to the original amount", arguments: weightedCases)
    private func partsSumToOriginal(_ weighted: WeightedCase) {
        let split = weighted.money.split(by: weighted.weights)

        #expect(split.amounts.reduce(GBP.zero, +) == weighted.money)
    }

    @Test("There is one part per weight, in weight order", arguments: weightedCases)
    private func onePartPerWeightInOrder(_ weighted: WeightedCase) {
        let split = weighted.money.split(by: weighted.weights)

        #expect(split.count == weighted.weightValues.count)
        #expect(split.weights == weighted.weightValues)
    }

    @Test("Each part is within one minor unit of its exact share", arguments: weightedCases)
    private func partsWithinOneUnitOfShare(_ weighted: WeightedCase) {
        let split = weighted.money.split(by: weighted.weights)
        let sum = weighted.weightValues.reduce(Int64(0)) { total, weight in total + Int64(Int(weight)) }
        let bound = GBP(minorUnits: sum)

        for part in split.parts {
            // Compare `part × sum` with `whole × weight` in minor units, so the check is exact integer
            // arithmetic with no rounding: Hamilton's method keeps the gap below one whole share.
            let scaledPart = part.amount * sum
            let exactShare = weighted.money * Int(part.weight)

            #expect((scaledPart - exactShare).magnitude < bound)
        }
    }
}
