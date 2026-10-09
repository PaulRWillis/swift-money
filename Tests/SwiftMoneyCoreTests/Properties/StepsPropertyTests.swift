import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

// Ordered bounds and two non-zero strides in minor units. A narrow band makes a stride as long as the
// span, or longer, common, which is where two strides give the same steps; a wide band spans the whole
// width of an amount with strides of at least 2⁵⁸ minor units, so offsets leave `Int64` while the
// steps stay few.
private struct StepsCase: Sendable, CustomTestStringConvertible {
    let lower: Int64
    let upper: Int64
    let stride: Int64
    let otherStride: Int64
    let currency: Currency

    var testDescription: String {
        "\(lower)...\(upper) by \(stride) and by \(otherStride) in \(currency)"
    }
}

private let narrowBand: ClosedRange<Int64> = -60 ... 60
private let wideStrides: ClosedRange<Int64> = 1 << 58 ... Int64.max

private func signed(_ magnitude: Int64, negative: Int64) -> Int64 {
    negative == 1 ? -magnitude : magnitude
}

private let stepsCases: [StepsCase] = samples(
    zip(
        zip3(Gen<Int64>.int(in: 0 ... 1), Gen<Int64>.int(in: 0 ... 1), Gen<Int64>.int(in: 0 ... 1)),
        zip3(
            Gen<Int64>.int(in: Int64.min ... Int64.max),
            Gen<Int64>.int(in: Int64.min ... Int64.max),
            Gen<Currency>.element(of: [.gbp, .jpy, Millicredits.currency])
        )
    ).flatMap { choice, raw in
        let isWide = choice.0 == 1
        let magnitude = isWide ? Gen<Int64>.int(in: wideStrides) : Gen<Int64>.int(in: 1 ... 150)
        let first = isWide ? raw.0 : raw.0 % (narrowBand.upperBound + 1)
        let second = isWide ? raw.1 : raw.1 % (narrowBand.upperBound + 1)

        return zip(magnitude, magnitude).map { stride, otherStride in
            StepsCase(
                lower: min(first, second),
                upper: max(first, second),
                stride: signed(stride, negative: choice.1),
                otherStride: signed(otherStride, negative: choice.2),
                currency: raw.2
            )
        }
    },
    seed: PropertySeed.steps,
    edges: [
        StepsCase(lower: 0, upper: 0, stride: 1, otherStride: -1, currency: .gbp),
        StepsCase(lower: 10, upper: 250, stride: 240, otherStride: 500, currency: .gbp),
        StepsCase(lower: 10, upper: 250, stride: -240, otherStride: 240, currency: .gbp),
        StepsCase(lower: Int64.min, upper: Int64.max, stride: 1 << 62, otherStride: -(1 << 62), currency: .jpy),
        StepsCase(lower: Int64.min, upper: Int64.max, stride: Int64.min, otherStride: Int64.max, currency: .gbp),
        StepsCase(lower: Int64.max - 3, upper: Int64.max, stride: 2, otherStride: 3, currency: Millicredits.currency),
    ]
)

private func runtimeSteps(_ sample: StepsCase, by minorUnits: Int64) throws -> Money.Steps {
    let range = try Money(minorUnits: sample.lower, currency: sample.currency)...Money(minorUnits: sample.upper, currency: sample.currency)
    let stride = try #require(Money.Stride(exactly: Money(minorUnits: minorUnits, currency: sample.currency)))

    return try range.steps(by: stride)
}

@Suite("Steps properties")
struct StepsPropertyTests {

    @Test("Steps start on the near bound, end on the far one, and are a stride apart but for the last gap", arguments: stepsCases)
    private func shape(_ sample: StepsCase) throws {
        let steps = try runtimeSteps(sample, by: sample.stride)
        let minorUnits = steps.map(\.minorUnits)
        let ascending = sample.stride > 0
        let gaps = zip(minorUnits, minorUnits.dropFirst()).map { Int128($1) - Int128($0) }
        let magnitude = Int128(sample.stride.magnitude)

        #expect(minorUnits.first == (ascending ? sample.lower : sample.upper))
        #expect(minorUnits.last == (ascending ? sample.upper : sample.lower))
        #expect(minorUnits.count == steps.count)
        #expect(gaps.allSatisfy { ascending ? $0 > 0 : $0 < 0 })
        #expect(gaps.dropLast().allSatisfy { $0.magnitude == magnitude })
        #expect(gaps.last.map { $0.magnitude <= magnitude } ?? true)
        #expect(steps.allSatisfy { $0.currency == sample.currency })
    }

    @Test("Every step is found at its own position without walking", arguments: stepsCases)
    private func findsEveryStep(_ sample: StepsCase) throws {
        let steps = try runtimeSteps(sample, by: sample.stride)

        #expect(steps.indices.allSatisfy { steps.firstIndex(of: steps[$0]) == $0 })
        #expect(steps.indices.allSatisfy { steps.contains(steps[$0]) })
    }

    @Test("Typed steps hold the same minor units as runtime ones", arguments: stepsCases)
    private func typedMatchesRuntime(_ sample: StepsCase) throws {
        let stride = try #require(GBP.Stride(exactly: GBP(minorUnits: sample.stride)))
        let typed = try (GBP(minorUnits: sample.lower) ... GBP(minorUnits: sample.upper)).steps(by: stride)
        let runtime = try runtimeSteps(sample, by: sample.stride)

        #expect(typed.map(\.minorUnits) == runtime.map(\.minorUnits))
        #expect(typed.stride.amount.minorUnits == runtime.stride.amount.minorUnits)
    }

    @Test("Steps are equal exactly when they hold the same amounts in the same order, and then hash equally", arguments: stepsCases)
    private func equality(_ sample: StepsCase) throws {
        let first = try runtimeSteps(sample, by: sample.stride)
        let second = try runtimeSteps(sample, by: sample.otherStride)

        #expect((first == second) == (Array(first) == Array(second)))
        #expect(first == second ? first.hashValue == second.hashValue : true)
        #expect(first == (try runtimeSteps(sample, by: sample.stride)))
    }

    @Test("index(approximating:rounding:) picks the step a search of every step picks, under every rule", arguments: stepsCases)
    private func indexForAmountMatchesSearch(_ sample: StepsCase) throws {
        let steps = try runtimeSteps(sample, by: sample.stride)
        let rules: [DirectedRoundingRule] = [.down, .up, .towardZero, .awayFromZero]

        for probe in probes(around: steps) {
            let amount = Money(minorUnits: probe, currency: sample.currency)
            for rule in rules {
                guard let searched = searchedIndex(for: probe, in: steps, rounding: rule) else {
                    #expect(throws: MoneyStepsRoundingError<AnyCurrency>.outOfBounds, "\(probe) by \(rule)") {
                        try steps.index(approximating: amount, rounding: rule)
                    }
                    continue
                }
                #expect(try steps.index(approximating: amount, rounding: rule) == searched, "\(probe) by \(rule)")
            }
        }
    }

    @Test("index(approximating:tiesTo:) picks the step a search of every step picks, under every tie-break", arguments: stepsCases)
    private func nearestIndexForAmountMatchesSearch(_ sample: StepsCase) throws {
        let steps = try runtimeSteps(sample, by: sample.stride)
        let ties: [TieBreakingRule] = [.even, .awayFromZero]

        for probe in probes(around: steps) {
            let amount = Money(minorUnits: probe, currency: sample.currency)
            for tie in ties {
                let searched = searchedNearestIndex(for: probe, in: steps, tiesTo: tie)
                #expect(try steps.index(approximating: amount, tiesTo: tie) == searched, "\(probe) ties to \(tie)")
            }
        }
    }

    @Test("A selection's amount is always the step at its index", arguments: stepsCases)
    private func selectionIsOnAStep(_ sample: StepsCase) throws {
        let steps = try runtimeSteps(sample, by: sample.stride)

        for probe in probes(around: steps) {
            let selection = try Money.Steps.Selection(approximating: Money(minorUnits: probe, currency: sample.currency), in: steps)
            #expect(selection.amount == steps[selection.index])
            #expect(selection.selecting(selection.index) == selection)
        }
    }
}

// The amounts worth rounding: zero and a minor unit either side, each end, a few steps at the start,
// middle and end, the amounts a minor unit either side of them, and the midpoints between neighbors.
private func probes(around steps: Money.Steps) -> [Int64] {
    let offsets = [0, 1, 2, steps.count / 2, steps.count - 3, steps.count - 2, steps.count - 1]
    let positions = Set(offsets.filter { $0 >= 0 && $0 < steps.count })
    var probes: [Int64] = [-1, 0, 1]

    for offset in positions.sorted() {
        let here = steps[steps.index(steps.startIndex, offsetBy: offset)].minorUnits
        probes.append(here)
        probes.append(contentsOf: [here.addingReportingOverflow(1), here.subtractingReportingOverflow(1)]
            .filter { !$0.overflow }
            .map(\.partialValue))
        if offset + 1 < steps.count {
            let next = steps[steps.index(steps.startIndex, offsetBy: offset + 1)].minorUnits
            probes.append(Int64(truncatingIfNeeded: (Int128(here) + Int128(next)) / 2))
        }
    }

    return probes
}

// The highest step at or below an amount and the lowest at or above, found by searching every step.
private func searchedNeighbors(
    of probe: Int64,
    in steps: Money.Steps
) -> (below: Money.Steps.Index?, above: Money.Steps.Index?) {
    let indices = Array(steps.indices)
    let below = indices.filter { steps[$0].minorUnits <= probe }.max { steps[$0].minorUnits < steps[$1].minorUnits }
    let above = indices.filter { steps[$0].minorUnits >= probe }.min { steps[$0].minorUnits < steps[$1].minorUnits }

    return (below, above)
}

// Rounds by searching every step, on the number line as `Double.rounded(_:)` does: `down` is the
// highest step at or below, `up` the lowest at or above, and `nil` when there is none. Zero rounds as
// a positive amount, so beyond every step `towardZero` acts as `down` for it and `awayFromZero` as
// `up`. When the two neighbors lie either side of zero, `towardZero` takes the one smaller in size and
// `awayFromZero` the larger, and neighbors of equal size give the one with the amount's sign under
// both.
private func searchedIndex(
    for probe: Int64,
    in steps: Money.Steps,
    rounding rule: DirectedRoundingRule
) -> Money.Steps.Index? {
    switch searchedNeighbors(of: probe, in: steps) {
    case let (below?, above?):
        return searchedIndex(for: probe, between: below, and: above, in: steps, rounding: rule)
    case let (below?, nil):
        return onlyNeighborSide(of: probe, rounding: rule) == .below ? below : nil
    case let (nil, above?):
        return onlyNeighborSide(of: probe, rounding: rule) == .above ? above : nil
    case (nil, nil):
        return nil
    }
}

// Which side of an amount beyond every step a rule takes its step from.
private enum Side {
    case below
    case above
}

private func onlyNeighborSide(of probe: Int64, rounding rule: DirectedRoundingRule) -> Side {
    switch rule {
    case .down: return .below
    case .up: return .above
    case .towardZero: return probe < 0 ? .above : .below
    case .awayFromZero: return probe < 0 ? .below : .above
    }
}

// Rounds an amount between two neighboring steps, or on one when both are the same step.
private func searchedIndex(
    for probe: Int64,
    between below: Money.Steps.Index,
    and above: Money.Steps.Index,
    in steps: Money.Steps,
    rounding rule: DirectedRoundingRule
) -> Money.Steps.Index {

    let positive = probe >= 0
    let belowSize = Int128(steps[below].minorUnits).magnitude
    let aboveSize = Int128(steps[above].minorUnits).magnitude
    let acrossZero = steps[below].minorUnits < 0 && steps[above].minorUnits > 0
    let sameSign = positive ? above : below
    let smaller = belowSize == aboveSize ? sameSign : (belowSize < aboveSize ? below : above)
    let larger = belowSize == aboveSize ? sameSign : (belowSize > aboveSize ? below : above)

    switch rule {
    case .down: return below
    case .up: return above
    case .towardZero: return acrossZero ? smaller : (positive ? below : above)
    case .awayFromZero: return acrossZero ? larger : (positive ? above : below)
    }
}

// Rounds to the nearest step by searching every step. Beyond every step that is the only neighbor.
// `even` breaks a tie toward the step at an even position counted from the lowest, and
// `awayFromZero` toward the step with the amount's sign, zero counting as positive.
private func searchedNearestIndex(
    for probe: Int64,
    in steps: Money.Steps,
    tiesTo tie: TieBreakingRule
) -> Money.Steps.Index? {
    switch searchedNeighbors(of: probe, in: steps) {
    case let (below?, above?):
        let toBelow = (Int128(probe) - Int128(steps[below].minorUnits)).magnitude
        let toAbove = (Int128(steps[above].minorUnits) - Int128(probe)).magnitude
        guard toBelow == toAbove else {
            return toBelow < toAbove ? below : above
        }
        switch tie {
        case .even:
            let belowPosition = steps.filter { $0.minorUnits < steps[below].minorUnits }.count
            return belowPosition.isMultiple(of: 2) ? below : above
        case .awayFromZero:
            return probe >= 0 ? above : below
        }
    case let (only?, nil), let (nil, only?):
        return only
    case (nil, nil):
        return nil
    }
}
