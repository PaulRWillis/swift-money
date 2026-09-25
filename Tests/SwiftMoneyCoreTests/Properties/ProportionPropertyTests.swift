import SwiftMoneyCore
import Testing

// A part and the whole it is measured against, with `0 < whole` and `0 ≤ part ≤ whole`.
private struct ProportionCase: Sendable {
    let part: GBP
    let whole: GBP
}

// `0 < whole ≤ 10¹²`. `proportion` divides at 18 fractional digits, so scaling the whole back by it
// carries an absolute error of at most whole·½·10⁻¹⁸ — below ½ a minor unit only while whole ≤ 10¹⁸, and
// comfortably so at 10¹². Nearer Int64.max the error reaches several units, which is why this bound is
// load-bearing, not cosmetic.
private let proportionWholeBound: Int64 = 1_000_000_000_000

private let proportionCases: [ProportionCase] = samples(
    Gen<Int64>.int(in: 1 ... proportionWholeBound).flatMap { whole in
        Gen<Int64>.int(in: 0 ... whole).map { part in
            ProportionCase(part: GBP(minorUnits: part), whole: GBP(minorUnits: whole))
        }
    },
    seed: PropertySeed.proportion,
    edges: [
        ProportionCase(part: .zero, whole: GBP(minorUnits: 1)),
        ProportionCase(part: GBP(minorUnits: 1), whole: GBP(minorUnits: 1)),
        ProportionCase(part: GBP(minorUnits: 1), whole: GBP(minorUnits: proportionWholeBound)),
        ProportionCase(part: GBP(minorUnits: proportionWholeBound), whole: GBP(minorUnits: proportionWholeBound)),
    ]
)

@Suite("Proportion properties")
struct ProportionPropertyTests {

    @Test("Proportion inverts applying within one minor unit", arguments: proportionCases)
    private func proportionInvertsApplying(_ proportion: ProportionCase) throws {
        // The whole is never zero, so `proportion(of:)` is never nil here.
        let fraction = try #require(proportion.part.proportion(of: proportion.whole))
        let restored = proportion.whole.applying(fraction).rounded(.toNearestOrEven)

        #expect((restored - proportion.part).magnitude <= GBP(minorUnits: 1))
    }
}
