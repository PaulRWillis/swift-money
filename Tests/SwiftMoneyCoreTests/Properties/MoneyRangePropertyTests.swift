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
