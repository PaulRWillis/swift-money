import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

// A start, an end and a non-zero stride in minor units. Two bands: a narrow one where sequences are
// short but land on, miss and overshoot their end often, and the full width of an amount with strides
// of at least 2⁵⁸ minor units, so steps overflow at either end without the sequence growing long.
private struct StrideCase: Sendable, CustomTestStringConvertible {
    let start: Int64
    let end: Int64
    let stride: Int64
    let currency: Currency

    var testDescription: String {
        "stride from \(start) to \(end) by \(stride) in \(currency)"
    }
}

private let narrowBand: ClosedRange<Int64> = -500 ... 500
private let wideStrides: ClosedRange<Int64> = 1 << 58 ... Int64.max

private func nonZero(_ magnitude: Int64, negative: Bool) -> Int64 {
    negative ? -magnitude : magnitude
}

/// Returns the given minor units, each with its neighbors a minor unit either side, leaving out a
/// neighbor beyond the range of `Int64`.
///
/// - Parameter minorUnits: The minor units to probe around.
/// - Returns: Each of `minorUnits`, one below it and one above it, where they fit `Int64`.
/// - Complexity: O(*n*), where *n* is the number of `minorUnits`.
private func withNeighbors(_ minorUnits: [Int64]) -> [Int64] {
    minorUnits.flatMap { value in
        [value.subtractingReportingOverflow(1), (partialValue: value, overflow: false), value.addingReportingOverflow(1)]
            .filter { !$0.overflow }
            .map(\.partialValue)
    }
}

private let strideCases: [StrideCase] = samples(
    zip(
        zip3(Gen<Int64>.int(in: 0 ... 1), Gen<Int64>.int(in: 0 ... 1), Gen<Int64>.int(in: 1 ... 60)),
        zip3(
            Gen<Int64>.int(in: Int64.min ... Int64.max),
            Gen<Int64>.int(in: Int64.min ... Int64.max),
            Gen<Currency>.element(of: [.gbp, .jpy, Millicredits.currency])
        )
    ).flatMap { choice, raw in
        let isWide = choice.0 == 1
        let isNegative = choice.1 == 1
        let magnitude = isWide ? Gen<Int64>.int(in: wideStrides) : Gen<Int64>.always(choice.2)

        return magnitude.map { stride in
            StrideCase(
                start: isWide ? raw.0 : raw.0 % (narrowBand.upperBound + 1),
                end: isWide ? raw.1 : raw.1 % (narrowBand.upperBound + 1),
                stride: nonZero(stride, negative: isNegative),
                currency: raw.2
            )
        }
    },
    seed: PropertySeed.stride,
    edges: [
        StrideCase(start: 0, end: 0, stride: 1, currency: .gbp),
        StrideCase(start: Int64.max - 1, end: Int64.max, stride: 5, currency: .gbp),
        StrideCase(start: Int64.min + 1, end: Int64.min, stride: -5, currency: .jpy),
        StrideCase(start: Int64.min, end: Int64.max, stride: Int64.max, currency: .gbp),
        StrideCase(start: Int64.max, end: Int64.min, stride: Int64.min, currency: .gbp),
        StrideCase(start: Int64.max, end: Int64.max, stride: 1, currency: Millicredits.currency),
        StrideCase(start: 0, end: Int64.max, stride: Int64.max, currency: .gbp),
    ]
)

// Only where `Int` is 64 bits: there `Swift.stride` over `Int64` takes an `Int64`-wide stride, so it
// is the reference. On 32-bit it would trap for the wide cases, which is why the amounts don't use it.
#if _pointerBitWidth(_64)
@Suite("stride properties")
struct StridePropertyTests {

    @Test("Typed amounts step exactly as Swift.stride over their minor units", arguments: strideCases)
    private func typedMatchesStandardLibrary(_ sample: StrideCase) throws {
        let step = try #require(GBP.Stride(exactly: GBP(minorUnits: sample.stride)))
        let to = stride(from: GBP(minorUnits: sample.start), to: GBP(minorUnits: sample.end), by: step)
        let through = stride(from: GBP(minorUnits: sample.start), through: GBP(minorUnits: sample.end), by: step)
        let rawTo = Swift.stride(from: sample.start, to: sample.end, by: Int(sample.stride))
        let rawThrough = Swift.stride(from: sample.start, through: sample.end, by: Int(sample.stride))

        #expect(to.map(\.minorUnits) == Array(rawTo))
        #expect(through.map(\.minorUnits) == Array(rawThrough))
        #expect(to.underestimatedCount == rawTo.underestimatedCount)
        #expect(through.underestimatedCount == rawThrough.underestimatedCount)
    }

    @Test("Runtime amounts step exactly as Swift.stride over their minor units, in their currency", arguments: strideCases)
    private func runtimeMatchesStandardLibrary(_ sample: StrideCase) throws {
        let start = Money(minorUnits: sample.start, currency: sample.currency)
        let end = Money(minorUnits: sample.end, currency: sample.currency)
        let step = try #require(Money.Stride(exactly: Money(minorUnits: sample.stride, currency: sample.currency)))
        let to = try stride(from: start, to: end, by: step)
        let through = try stride(from: start, through: end, by: step)

        #expect(to.map(\.minorUnits) == Array(Swift.stride(from: sample.start, to: sample.end, by: Int(sample.stride))))
        #expect(through.map(\.minorUnits) == Array(Swift.stride(from: sample.start, through: sample.end, by: Int(sample.stride))))
        #expect(to.allSatisfy { $0.currency == sample.currency })
        #expect(through.allSatisfy { $0.currency == sample.currency })
    }

    @Test("A typed stride contains exactly the amounts stepping through it gives, and none beside them", arguments: strideCases)
    private func typedContainsMatchesStepping(_ sample: StrideCase) throws {
        let step = try #require(GBP.Stride(exactly: GBP(minorUnits: sample.stride)))
        let to = stride(from: GBP(minorUnits: sample.start), to: GBP(minorUnits: sample.end), by: step)
        let through = stride(from: GBP(minorUnits: sample.start), through: GBP(minorUnits: sample.end), by: step)
        // Every case is short enough to step through in full: a narrow one holds at most about a
        // thousand amounts, and a wide one, with strides of at least 2⁵⁸, at most about sixty-five.
        let steppedTo = Set(to.map(\.minorUnits))
        let steppedThrough = Set(through.map(\.minorUnits))

        for minorUnits in withNeighbors(Array(steppedThrough) + [sample.start, sample.end]) {
            #expect(to.contains(GBP(minorUnits: minorUnits)) == steppedTo.contains(minorUnits))
            #expect(through.contains(GBP(minorUnits: minorUnits)) == steppedThrough.contains(minorUnits))
        }
    }

    @Test("A runtime stride contains exactly the amounts stepping through it gives, in its currency only", arguments: strideCases)
    private func runtimeContainsMatchesStepping(_ sample: StrideCase) throws {
        let start = Money(minorUnits: sample.start, currency: sample.currency)
        let end = Money(minorUnits: sample.end, currency: sample.currency)
        let step = try #require(Money.Stride(exactly: Money(minorUnits: sample.stride, currency: sample.currency)))
        let to = try stride(from: start, to: end, by: step)
        let through = try stride(from: start, through: end, by: step)
        let steppedTo = Set(to.map(\.minorUnits))
        let steppedThrough = Set(through.map(\.minorUnits))
        // The corpus never uses euros.
        let otherCurrency = Currency.eur

        for minorUnits in withNeighbors(Array(steppedThrough) + [sample.start, sample.end]) {
            let amount = Money(minorUnits: minorUnits, currency: sample.currency)

            #expect(to.contains(amount) == steppedTo.contains(minorUnits))
            #expect(through.contains(amount) == steppedThrough.contains(minorUnits))
            #expect(!through.contains(Money(minorUnits: minorUnits, currency: otherCurrency)))
        }
    }
}
#endif
