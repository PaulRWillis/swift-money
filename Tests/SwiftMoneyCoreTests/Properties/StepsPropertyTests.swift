import SwiftMoneyCore
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
}
