import SwiftMoneyCore
import Testing

// An amount and a rate to scale it by, for the settling and scale-by-one properties.
private struct RateCase: Sendable {
    let money: GBP
    let rate: Rate
}

// An amount and a whole number to divide then re-multiply by.
private struct DivideCase: Sendable {
    let money: GBP
    let divisor: Int
}

// Three amounts, for the additive-group laws on `Unrounded`.
private struct UnroundedTriple: Sendable {
    let a: GBP
    let b: GBP
    let c: GBP
}

// |minorUnits| ≤ 10⁹ and rate ≤ 10⁶, so an applied product reaches 10¹⁵ minor units — well inside
// `Fixed`'s ±1.7×10²⁰ range, and inside Int64 once settled. Held as an `Unrounded`, that is a storage
// integer of 10¹⁵ × 10¹⁸ = 10³³, still far below Int128.max (~1.7×10³⁸).
private let unroundedAmountBound: Int64 = 1_000_000_000
private let unroundedRateSignificandBound: Int64 = 1_000_000

// Divide-then-multiply keeps `|money| ≤ 10¹²` and `1 ≤ n ≤ 10³`: dividing rounds at 18 fractional
// digits, and multiplying by `n` grows that error to at most n·½·10⁻¹⁸ ≪ ½ a minor unit, so the value
// settles back exactly.
private let divideAmountBound: Int64 = 1_000_000_000_000
private let maxDivisor: Int64 = 1_000

// Every rounding rule the settling properties must hold under. `FloatingPointRoundingRule` is not
// `CaseIterable`, so the list is written out.
private let roundingRules: [RoundingRule] = [
    .toNearestOrAwayFromZero,
    .toNearestOrEven,
    .up,
    .down,
    .towardZero,
    .awayFromZero,
]

// The round-to-nearest rules, the only ones under which divide-then-multiply settles back exactly.
// Dividing then multiplying leaves the value a few parts in 10¹⁸ off the whole minor unit; a nearest
// rule absorbs that (it is far below ½), but a directional rule (`.up`, `.down`, `.towardZero`,
// `.awayFromZero`) turns even a 10⁻¹⁸ residue into a whole-unit step, so it does not.
private let nearestRoundingRules: [RoundingRule] = [
    .toNearestOrAwayFromZero,
    .toNearestOrEven,
]

private let rateCases: [RateCase] = samples(
    zip(
        .typedMoney(minorUnitsIn: -unroundedAmountBound ... unroundedAmountBound),
        Gen<Rate>.rate(significandIn: 0 ... unroundedRateSignificandBound, denominators: Gen<Rate>.decimalDenominators)
    ).map { RateCase(money: $0, rate: $1) },
    seed: PropertySeed.unrounded,
    edges: [
        RateCase(money: .zero, rate: "0"),
        RateCase(money: GBP(minorUnits: 1), rate: "1"),
        RateCase(money: GBP(minorUnits: unroundedAmountBound), rate: "0.5"),
        RateCase(money: GBP(minorUnits: -unroundedAmountBound), rate: "0.333333"),
    ]
)

private let divideCases: [DivideCase] = samples(
    zip(
        .typedMoney(minorUnitsIn: -divideAmountBound ... divideAmountBound),
        Gen<Int64>.int(in: 1 ... maxDivisor).map { Int($0) }
    ).map { DivideCase(money: $0, divisor: $1) },
    seed: PropertySeed.unrounded,
    edges: [
        DivideCase(money: .zero, divisor: 1),
        DivideCase(money: GBP(minorUnits: 1), divisor: 3),
        DivideCase(money: GBP(minorUnits: divideAmountBound), divisor: 7),
        DivideCase(money: GBP(minorUnits: -divideAmountBound), divisor: Int(maxDivisor)),
    ]
)

private let unroundedTriples: [UnroundedTriple] = samples(
    zip3(
        .typedMoney(minorUnitsIn: -unroundedAmountBound ... unroundedAmountBound),
        .typedMoney(minorUnitsIn: -unroundedAmountBound ... unroundedAmountBound),
        .typedMoney(minorUnitsIn: -unroundedAmountBound ... unroundedAmountBound)
    ).map { UnroundedTriple(a: $0, b: $1, c: $2) },
    seed: PropertySeed.unrounded,
    edges: [
        UnroundedTriple(a: .zero, b: .zero, c: .zero),
        UnroundedTriple(a: GBP(minorUnits: 1), b: GBP(minorUnits: -1), c: .zero),
        UnroundedTriple(
            a: GBP(minorUnits: unroundedAmountBound),
            b: GBP(minorUnits: -unroundedAmountBound),
            c: GBP(minorUnits: 1)
        ),
    ]
)

@Suite("Unrounded scaling and settling properties")
struct UnroundedPropertyTests {

    @Test("Settling lands within one minor unit for every rule", arguments: rateCases)
    private func settlesWithinOneUnit(_ rateCase: RateCase) {
        let exact = rateCase.money.applying(rateCase.rate)

        for rule in roundingRules {
            let settled = exact.rounded(rule)
            // Truncating the residue toward zero gives zero exactly when |residue| < 1 minor unit, which
            // is the real "within one of the exact figure" guarantee.
            #expect((exact - settled).rounded(.towardZero) == GBP.zero)
        }
    }

    @Test("A settled amount plus its residue is the exact product", arguments: rateCases)
    private func settledPlusResidueIsExact(_ rateCase: RateCase) {
        let exact = rateCase.money.applying(rateCase.rate)

        for rule in roundingRules {
            let settled = exact.rounded(rule)
            let residue = exact - settled
            #expect(settled + residue == exact)
        }
    }

    @Test("Scaling by one settles back to the original", arguments: rateCases)
    private func scaleByOneIsIdentity(_ rateCase: RateCase) {
        for rule in roundingRules {
            #expect(rateCase.money.applying("1").rounded(rule) == rateCase.money)
            #expect((rateCase.money.unrounded * "3/3").rounded(rule) == rateCase.money)
        }
    }

    @Test("Dividing then multiplying by the same number settles back", arguments: divideCases)
    private func divideThenMultiply(_ divideCase: DivideCase) {
        for rule in nearestRoundingRules {
            let restored = (divideCase.money.unrounded.divided(by: divideCase.divisor) * divideCase.divisor).rounded(rule)
            #expect(restored == divideCase.money)
        }
    }

    @Test("Unrounded addition is commutative", arguments: unroundedTriples)
    private func unroundedCommutativity(_ triple: UnroundedTriple) {
        #expect(triple.a.unrounded + triple.b.unrounded == triple.b.unrounded + triple.a.unrounded)
    }

    @Test("Unrounded addition is associative", arguments: unroundedTriples)
    private func unroundedAssociativity(_ triple: UnroundedTriple) {
        let left = (triple.a.unrounded + triple.b.unrounded) + triple.c.unrounded
        let right = triple.a.unrounded + (triple.b.unrounded + triple.c.unrounded)

        #expect(left == right)
    }

    @Test("Zero is the unrounded additive identity", arguments: unroundedTriples)
    private func unroundedIdentity(_ triple: UnroundedTriple) {
        #expect(triple.a.unrounded + GBP.Unrounded.zero == triple.a.unrounded)
    }
}
