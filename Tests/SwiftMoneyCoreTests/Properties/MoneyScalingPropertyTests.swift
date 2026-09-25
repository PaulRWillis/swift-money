import SwiftMoneyCore
import Testing

// One amount and the whole numbers it is scaled by, the operands of the ring-multiplication laws. Two
// amounts are carried because the chained-associativity law needs a tighter bound than the rest.
private struct ScaleCase: Sendable {
    let money: GBP
    let chainMoney: GBP
    let factorA: Int
    let factorB: Int
    let repeatCount: Int
}

// |minorUnits| ≤ 10⁶ and |factor| ≤ 10³, so a single product `money × factor` reaches 10⁹, and
// distributivity's `money × (a + b)` reaches 2×10⁹ — both far below Int64.max (~9.2×10¹⁸).
private let scalingAmountBound: Int64 = 1_000_000
private let scalingFactorBound: Int64 = 1_000

// The chained law multiplies twice: `(chainMoney × a) × b` with all three of |chainMoney|, |a|, |b|
// ≤ 10³ reaches 10⁹.
private let chainAmountBound: Int64 = 1_000

// Repeated addition sums at most this many copies of `money`; 10⁶ × 100 = 10⁸ stays in range.
private let repeatBound: Int64 = 100

private let factorRange = -scalingFactorBound ... scalingFactorBound

private let scaleEdges: [ScaleCase] = [
    ScaleCase(money: .zero, chainMoney: .zero, factorA: 0, factorB: 0, repeatCount: 0),
    ScaleCase(money: GBP(minorUnits: 1), chainMoney: GBP(minorUnits: 1), factorA: 1, factorB: -1, repeatCount: 1),
    ScaleCase(
        money: GBP(minorUnits: scalingAmountBound),
        chainMoney: GBP(minorUnits: chainAmountBound),
        factorA: Int(scalingFactorBound),
        factorB: -Int(scalingFactorBound),
        repeatCount: Int(repeatBound)
    ),
]

private let scaleCases: [ScaleCase] = samples(
    zip(
        zip3(
            .typedMoney(minorUnitsIn: -scalingAmountBound ... scalingAmountBound),
            .typedMoney(minorUnitsIn: -chainAmountBound ... chainAmountBound),
            Gen<Int64>.int(in: factorRange).map { Int($0) }
        ),
        zip(
            Gen<Int64>.int(in: factorRange).map { Int($0) },
            Gen<Int64>.int(in: 0 ... repeatBound).map { Int($0) }
        )
    ).map { first, second in
        ScaleCase(money: first.0, chainMoney: first.1, factorA: first.2, factorB: second.0, repeatCount: second.1)
    },
    seed: PropertySeed.scaling,
    edges: scaleEdges
)

@Suite("MoneyOf scalar-multiplication properties")
struct MoneyScalingPropertyTests {

    @Test("Scaling by one is the identity", arguments: scaleCases)
    private func scaleByOne(_ scale: ScaleCase) {
        #expect(scale.money * 1 == scale.money)
    }

    @Test("Scaling by zero is zero", arguments: scaleCases)
    private func scaleByZero(_ scale: ScaleCase) {
        #expect(scale.money * 0 == .zero)
    }

    @Test("Scaling by a whole number equals repeated addition", arguments: scaleCases)
    private func repeatedAddition(_ scale: ScaleCase) {
        let summed = (0 ..< scale.repeatCount).reduce(GBP.zero) { total, _ in total + scale.money }

        #expect(scale.money * scale.repeatCount == summed)
    }

    @Test("Left and right multiplication agree", arguments: scaleCases)
    private func leftRightAgreement(_ scale: ScaleCase) {
        #expect(scale.money * scale.factorA == scale.factorA * scale.money)
    }

    @Test("Multiplication distributes over addition", arguments: scaleCases)
    private func distributivity(_ scale: ScaleCase) {
        #expect(scale.money * (scale.factorA + scale.factorB) == scale.money * scale.factorA + scale.money * scale.factorB)
    }

    @Test("Chained multiplication is associative", arguments: scaleCases)
    private func associativity(_ scale: ScaleCase) {
        #expect((scale.chainMoney * scale.factorA) * scale.factorB == scale.chainMoney * (scale.factorA * scale.factorB))
    }
}
