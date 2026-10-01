import SwiftMoneyCore
import Testing

// Two ordered pairs of minor units and a probe, the raw material for two ranges and an amount. The
// bounds are drawn from a narrow band so ranges touch, nest and overlap often, not only rarely.
private struct RangePair: Sendable, CustomTestStringConvertible {
    let first: ClosedRange<Int64>
    let second: ClosedRange<Int64>
    let probe: Int64
    let currency: Currency

    var testDescription: String {
        "\(first) vs \(second), probe \(probe) in \(currency)"
    }
}

private func ordered(_ a: Int64, _ b: Int64) -> ClosedRange<Int64> {
    min(a, b) ... max(a, b)
}

private let band: ClosedRange<Int64> = -20 ... 20

private let rangePairs: [RangePair] = samples(
    zip(
        zip(zip3(Gen<Int64>.int(in: band), Gen<Int64>.int(in: band), Gen<Int64>.int(in: band)), Gen<Int64>.int(in: band)),
        zip(Gen<Int64>.int(in: band), Gen<Currency>.element(of: [.gbp, .jpy, Millicredits.currency]))
    ).map { bounds, rest in
        RangePair(
            first: ordered(bounds.0.0, bounds.0.1),
            second: ordered(bounds.0.2, bounds.1),
            probe: rest.0,
            currency: rest.1
        )
    },
    seed: PropertySeed.ranges,
    edges: [
        RangePair(first: 0 ... 0, second: 0 ... 0, probe: 0, currency: .gbp),
        RangePair(first: Int64.min ... Int64.max, second: Int64.max ... Int64.max, probe: Int64.min, currency: .jpy),
        RangePair(first: 0 ... 100, second: 0 ... 101, probe: 101, currency: .gbp),
    ]
)

@Suite("Money range properties")
struct MoneyRangePropertyTests {

    private func money(_ minorUnits: Int64, _ currency: Currency) -> Money {
        Money(minorUnits: minorUnits, currency: currency)
    }

    private func closed(_ range: ClosedRange<Int64>, _ currency: Currency) throws -> ClosedMoneyRange {
        try money(range.lowerBound, currency)...money(range.upperBound, currency)
    }

    private func halfOpen(_ range: ClosedRange<Int64>, _ currency: Currency) throws -> MoneyRange {
        try money(range.lowerBound, currency)..<money(range.upperBound, currency)
    }

    @Test("Closed ranges answer as ClosedRange<Int64> over the same minor units", arguments: rangePairs)
    private func closedMatchesStandardLibrary(_ pair: RangePair) throws {
        let first = try closed(pair.first, pair.currency)
        let second = try closed(pair.second, pair.currency)
        let halfOpenSecond = try halfOpen(pair.second, pair.currency)
        let rawHalfOpenSecond = pair.second.lowerBound ..< pair.second.upperBound

        #expect(try first.contains(money(pair.probe, pair.currency)) == pair.first.contains(pair.probe))
        #expect(try first.contains(second) == pair.first.contains(pair.second))
        #expect(try first.contains(halfOpenSecond) == pair.first.contains(rawHalfOpenSecond))
        #expect(try first.overlaps(second) == pair.first.overlaps(pair.second))
        #expect(try first.overlaps(halfOpenSecond) == pair.first.overlaps(rawHalfOpenSecond))

        let clamped = try first.clamped(to: second)
        let rawClamped = pair.first.clamped(to: pair.second)
        #expect(clamped.lowerBound == money(rawClamped.lowerBound, pair.currency))
        #expect(clamped.upperBound == money(rawClamped.upperBound, pair.currency))
    }

    @Test("Half-open ranges answer as Range<Int64> over the same minor units", arguments: rangePairs)
    private func halfOpenMatchesStandardLibrary(_ pair: RangePair) throws {
        let first = try halfOpen(pair.first, pair.currency)
        let second = try halfOpen(pair.second, pair.currency)
        let closedSecond = try closed(pair.second, pair.currency)
        let rawFirst = pair.first.lowerBound ..< pair.first.upperBound
        let rawSecond = pair.second.lowerBound ..< pair.second.upperBound

        #expect(try first.contains(money(pair.probe, pair.currency)) == rawFirst.contains(pair.probe))
        #expect(try first.contains(second) == rawFirst.contains(rawSecond))
        #expect(try first.contains(closedSecond) == rawFirst.contains(pair.second))
        #expect(try first.overlaps(second) == rawFirst.overlaps(rawSecond))
        #expect(try first.overlaps(closedSecond) == rawFirst.overlaps(pair.second))
        #expect(first.isEmpty == rawFirst.isEmpty)

        let clamped = try first.clamped(to: second)
        let rawClamped = rawFirst.clamped(to: rawSecond)
        #expect(clamped.lowerBound == money(rawClamped.lowerBound, pair.currency))
        #expect(clamped.upperBound == money(rawClamped.upperBound, pair.currency))
    }

    @Test("A typed closed range contains a half-open one as ClosedRange<Int64> does", arguments: rangePairs)
    private func typedClosedContainsHalfOpen(_ pair: RangePair) throws {
        let first = GBP(minorUnits: pair.first.lowerBound) ... GBP(minorUnits: pair.first.upperBound)
        let second = GBP(minorUnits: pair.second.lowerBound) ..< GBP(minorUnits: pair.second.upperBound)

        #expect(first.contains(second) == pair.first.contains(pair.second.lowerBound ..< pair.second.upperBound))
        #expect(try ClosedMoneyRange(first).contains(MoneyRange(second)) == first.contains(second))
    }

    @Test("Clamping an amount matches min and max on its minor units", arguments: rangePairs)
    private func amountClampingMatchesMinAndMax(_ pair: RangePair) throws {
        let (probe, lower, upper) = (pair.probe, pair.first.lowerBound, pair.first.upperBound)
        let amount = money(probe, pair.currency)
        let typed = GBP(minorUnits: probe)

        let clampedToClosed = try amount.clamped(to: closed(pair.first, pair.currency))
        #expect(clampedToClosed == money(Swift.min(Swift.max(probe, lower), upper), pair.currency))
        #expect(try amount.clamped(to: money(lower, pair.currency)...) == money(Swift.max(probe, lower), pair.currency))
        #expect(try amount.clamped(to: ...money(upper, pair.currency)) == money(Swift.min(probe, upper), pair.currency))

        let typedLimits = GBP(minorUnits: lower) ... GBP(minorUnits: upper)
        #expect(typed.clamped(to: typedLimits) == GBP(minorUnits: Swift.min(Swift.max(probe, lower), upper)))
        #expect(typed.clamped(to: GBP(minorUnits: lower)...) == GBP(minorUnits: Swift.max(probe, lower)))
        #expect(typed.clamped(to: ...GBP(minorUnits: upper)) == GBP(minorUnits: Swift.min(probe, upper)))
    }

    @Test("Partial runtime ranges contain an amount as comparisons on minor units do", arguments: rangePairs)
    private func partialContainsMatchesComparisons(_ pair: RangePair) throws {
        let (probe, lower, upper) = (pair.probe, pair.first.lowerBound, pair.first.upperBound)
        let amount = money(probe, pair.currency)

        #expect(try (money(lower, pair.currency)...).contains(amount) == (probe >= lower))
        #expect(try (...money(upper, pair.currency)).contains(amount) == (probe <= upper))
        #expect(try (..<money(upper, pair.currency)).contains(amount) == (probe < upper))
    }

    @Test("A closed range round-trips through a half-open one unless it ends at the maximum", arguments: rangePairs)
    private func closedToHalfOpenRoundTrip(_ pair: RangePair) throws {
        let range = try closed(pair.first, pair.currency)
        let converted = MoneyRange(range)

        guard pair.first.upperBound < Int64.max else {
            #expect(converted == nil)
            return
        }
        let wider = try money(pair.first.lowerBound, pair.currency)..<money(pair.first.upperBound + 1, pair.currency)
        #expect(converted == wider)
        #expect(converted.flatMap { ClosedMoneyRange($0) } == range)
    }

    @Test("A non-empty half-open range round-trips through a closed one", arguments: rangePairs)
    private func halfOpenToClosedRoundTrip(_ pair: RangePair) throws {
        let range = try halfOpen(pair.first, pair.currency)
        let converted = ClosedMoneyRange(range)

        guard pair.first.lowerBound < pair.first.upperBound else {
            #expect(converted == nil)
            return
        }
        let narrower = try money(pair.first.lowerBound, pair.currency)...money(pair.first.upperBound - 1, pair.currency)
        #expect(converted == narrower)
        #expect(converted.flatMap { MoneyRange($0) } == range)
    }

    @Test("Partial ranges keep their bound through a typed and runtime round trip", arguments: rangePairs)
    private func partialRoundTrip(_ pair: RangePair) throws {
        let typed = GBP(minorUnits: pair.probe)
        let runtime = Money(minorUnits: pair.probe, currency: .gbp)

        #expect(try PartialRangeFrom<GBP>(PartialMoneyRangeFrom(typed...)).lowerBound == typed)
        #expect(try PartialRangeThrough<GBP>(PartialMoneyRangeThrough(...typed)).upperBound == typed)
        #expect(try PartialRangeUpTo<GBP>(PartialMoneyRangeUpTo(..<typed)).upperBound == typed)
        #expect(try PartialMoneyRangeFrom(PartialRangeFrom<GBP>(runtime...)) == runtime...)
        #expect(try PartialMoneyRangeThrough(PartialRangeThrough<GBP>(...runtime)) == ...runtime)
        #expect(try PartialMoneyRangeUpTo(PartialRangeUpTo<GBP>(..<runtime)) == ..<runtime)
    }

    @Test("Equal ranges hash equally, and a range never equals one in another currency", arguments: rangePairs)
    private func hashing(_ pair: RangePair) throws {
        let first = try closed(pair.first, pair.currency)
        let again = try closed(pair.first, pair.currency)
        let other = pair.currency == .gbp ? Currency.eur : .gbp

        #expect(first == again)
        #expect(first.hashValue == again.hashValue)
        #expect(try first != closed(pair.first, other))
        #expect(try halfOpen(pair.first, pair.currency).hashValue == halfOpen(pair.first, pair.currency).hashValue)
        #expect(try halfOpen(pair.first, pair.currency) != halfOpen(pair.first, other))
    }
}
