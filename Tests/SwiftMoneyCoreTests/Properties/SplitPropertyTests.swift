import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

// An amount and the number of parts it is split into.
private struct SplitCase: Sendable {
    let money: GBP
    let parts: PartCount
}

// |minorUnits| ≤ 10⁹: every part is at most the whole, and the running sum only grows toward it, so no
// intermediate leaves the range. The part count reaches 10³, which is what makes this generalise well
// beyond the fixed pairs `SplitTests` covers.
private let splitAmountBound: Int64 = 1_000_000_000
private let maxSplitParts: Int64 = 1_000

private func splitCase(_ money: GBP, _ parts: PartCount) -> SplitCase {
    SplitCase(money: money, parts: parts)
}

private let splitEdges: [SplitCase] = [
    splitCase(.zero, 1),
    splitCase(GBP(minorUnits: 1), PartCount(exactly: Int(maxSplitParts)) ?? 1),
    splitCase(GBP(minorUnits: -1), 3),
    splitCase(GBP(minorUnits: splitAmountBound), 7),
    splitCase(GBP(minorUnits: -splitAmountBound), PartCount(exactly: Int(maxSplitParts)) ?? 1),
]

private let splitCases: [SplitCase] = samples(
    zip(
        .typedMoney(minorUnitsIn: -splitAmountBound ... splitAmountBound),
        Gen<PartCount>.partCount(in: 1 ... maxSplitParts)
    ).map(splitCase),
    seed: PropertySeed.split,
    edges: splitEdges
)

@Suite("Split properties")
struct SplitPropertyTests {

    @Test("The parts sum to the original amount", arguments: splitCases)
    private func partsSumToOriginal(_ split: SplitCase) {
        let parts = split.money.split(into: split.parts)

        #expect(parts.amounts.reduce(GBP.zero, +) == split.money)
    }

    @Test("The part count equals the requested count", arguments: splitCases)
    private func partCountMatches(_ split: SplitCase) {
        let parts = split.money.split(into: split.parts)

        #expect(parts.count == split.parts)
        #expect(Array(parts.amounts).count == Int(split.parts))
    }

    @Test("No two parts differ by more than one minor unit", arguments: splitCases)
    private func spreadIsAtMostOneUnit(_ split: SplitCase) {
        switch split.money.split(into: split.parts) {
        case .even:
            break   // Every part is equal, so there is no spread to check.
        case let .uneven(uneven):
            let spread = uneven.largerAmount - uneven.smallerAmount
            #expect(spread == GBP(minorUnits: 1) || spread == GBP(minorUnits: -1))
        }
    }

    @Test("A split is even exactly when the count divides the amount", arguments: splitCases)
    private func evenIffDivisible(_ split: SplitCase) {
        let isEven: Bool
        switch split.money.split(into: split.parts) {
        case .even:
            isEven = true
        case .uneven:
            isEven = false
        }

        // A part count is at least one, so this divisor is never zero.
        let divisor = GBP(minorUnits: Int64(Int(split.parts)))
        #expect(isEven == split.money.isMultiple(of: divisor))
    }

    @Test("A split's counts sum to the part count", arguments: splitCases)
    private func countsSumToPartCount(_ split: SplitCase) {
        switch split.money.split(into: split.parts) {
        case let .even(even):
            #expect(even.count == split.parts)
        case let .uneven(uneven):
            #expect(Int(uneven.largerCount) + Int(uneven.smallerCount) == Int(split.parts))
            #expect(uneven.count == split.parts)
        }
    }

    @Test("Each amount appears as many times as its count", arguments: splitCases)
    private func eachAmountAppearsAsManyTimesAsItsCount(_ split: SplitCase) {
        let parts = split.money.split(into: split.parts)

        let expected: [GBP]
        switch parts {
        case let .even(even):
            expected = Array(repeating: even.amount, count: Int(even.count))
        case let .uneven(uneven):
            expected = Array(repeating: uneven.largerAmount, count: Int(uneven.largerCount))
                + Array(repeating: uneven.smallerAmount, count: Int(uneven.smallerCount))
        }

        #expect(Array(parts.amounts) == expected)
    }

    @Test("The larger amount is one unit further from zero", arguments: splitCases)
    private func largerAmountIsOneUnitFurtherFromZero(_ split: SplitCase) {
        switch split.money.split(into: split.parts) {
        case .even:
            break   // An even split has no larger amount.
        case let .uneven(uneven):
            // Zero always splits evenly, so an uneven split's amount is positive or negative.
            let oneUnitAway = split.money.isPositive ? GBP(minorUnits: 1) : GBP(minorUnits: -1)
            #expect(uneven.largerAmount - uneven.smallerAmount == oneUnitAway)
        }
    }
}
