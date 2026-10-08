import SwiftMoneyCore
import Testing

// Two runtime amounts, in one currency or in two, for the min and max properties.
private struct AmountPair: Sendable, CustomTestStringConvertible {
    let first: Money
    let second: Money

    var testDescription: String {
        "\(first), \(second)"
    }
}

// The full range, since comparing never overflows.
private let fullRange: ClosedRange<Int64> = Int64.min ... Int64.max

private func pair(_ first: Money, _ second: Money) -> AmountPair {
    AmountPair(first: first, second: second)
}

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

private let sameCurrencyPairs: [AmountPair] = samples(
    Gen<Money>.runtimeMoneyPair(minorUnitsIn: fullRange, currency: .isoCurrency).map { pair($0, $1) },
    seed: PropertySeed.minMax,
    edges: [
        pair(pounds(0), pounds(0)),
        pair(pounds(-1), pounds(1)),
        pair(pounds(Int64.min), pounds(Int64.max)),
        pair(pounds(Int64.max), pounds(Int64.min)),
        pair(pounds(Int64.max), pounds(Int64.max)),
    ]
)

// Ordered pairs of distinct currencies, so every pair mismatches.
private let mismatchCurrencyPairs: [(Currency, Currency)] = [(.gbp, .eur), (.eur, .usd), (.usd, .jpy), (.jpy, .gbp)]

private let mismatchPairs: [AmountPair] = samples(
    zip(
        Gen<(Currency, Currency)>.element(of: mismatchCurrencyPairs),
        zip(Gen<Int64>.int(in: fullRange), Gen<Int64>.int(in: fullRange))
    ).map { currencies, units in
        pair(Money(minorUnits: units.0, currency: currencies.0), Money(minorUnits: units.1, currency: currencies.1))
    },
    seed: PropertySeed.minMax
)

@Suite("min and max properties")
struct MinMaxPropertyTests {

    @Test("min and max of two amounts match Swift.min and Swift.max on their minor units", arguments: sameCurrencyPairs)
    private func matchesStandardLibrary(_ pair: AmountPair) throws {
        let currency = pair.first.currency
        let (first, second) = (pair.first.minorUnits, pair.second.minorUnits)

        #expect(try min(pair.first, pair.second) == Money(minorUnits: Swift.min(first, second), currency: currency))
        #expect(try max(pair.first, pair.second) == Money(minorUnits: Swift.max(first, second), currency: currency))
    }

    @Test("min and max of two amounts return the pair, one each", arguments: sameCurrencyPairs)
    private func permutationOfThePair(_ pair: AmountPair) throws {
        let smaller = try min(pair.first, pair.second)
        let larger = try max(pair.first, pair.second)

        #expect((smaller, larger) == (pair.first, pair.second) || (smaller, larger) == (pair.second, pair.first))
    }

    @Test("min and max of amounts in two currencies throw a mismatch, the first currency first", arguments: mismatchPairs)
    private func mismatchThrows(_ pair: AmountPair) {
        let mismatch = MoneyError.currencyMismatch(lhs: pair.first.currency, rhs: pair.second.currency)

        #expect(throws: mismatch) { try min(pair.first, pair.second) }
        #expect(throws: mismatch) { try max(pair.first, pair.second) }
    }
}
