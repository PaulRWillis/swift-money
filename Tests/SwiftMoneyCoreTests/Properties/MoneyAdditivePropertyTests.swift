import SwiftMoneyCore
import Testing

// Three amounts of one currency, the operands of the additive-group laws.
private struct AdditiveTriple<Amount: Sendable>: Sendable {
    let a: Amount
    let b: Amount
    let c: Amount
}

// Two amounts in deliberately different currencies, for the illegal-state property.
private struct MismatchPair: Sendable {
    let lhs: Money
    let rhs: Money
}

// |minorUnits| ≤ 10⁹, so the largest expression under test — a three-term sum — reaches 3×10⁹, far
// below Int64.max (~9.2×10¹⁸). The bound also keeps every value clear of Int64.min, whose negation
// (needed by the inverse law) would trap.
private let additiveAmountBound: Int64 = 1_000_000_000

private let additiveAmountRange = -additiveAmountBound ... additiveAmountBound

private func triple<Amount>(_ a: Amount, _ b: Amount, _ c: Amount) -> AdditiveTriple<Amount> {
    AdditiveTriple(a: a, b: b, c: c)
}

// The boundary combinations a shrinker would converge on: zero, ±1, and the range extremes in the
// sign mixes the laws are most likely to break on.
private let typedEdges: [AdditiveTriple<GBP>] = [
    triple(.zero, .zero, .zero),
    triple(GBP(minorUnits: 1), GBP(minorUnits: -1), .zero),
    triple(GBP(minorUnits: additiveAmountBound), GBP(minorUnits: additiveAmountBound), GBP(minorUnits: -additiveAmountBound)),
    triple(GBP(minorUnits: -additiveAmountBound), GBP(minorUnits: 1), GBP(minorUnits: -1)),
]

private let typedTriples: [AdditiveTriple<GBP>] = samples(
    zip3(
        .typedMoney(minorUnitsIn: additiveAmountRange),
        .typedMoney(minorUnitsIn: additiveAmountRange),
        .typedMoney(minorUnitsIn: additiveAmountRange)
    ).map { triple($0, $1, $2) },
    seed: PropertySeed.additive,
    edges: typedEdges
)

private let runtimeTriples: [AdditiveTriple<Money>] = samples(
    zip(
        Gen<Currency>.isoCurrency,
        zip3(
            Gen<Int64>.int(in: additiveAmountRange),
            Gen<Int64>.int(in: additiveAmountRange),
            Gen<Int64>.int(in: additiveAmountRange)
        )
    ).map { currency, amounts in
        triple(
            Money(minorUnits: amounts.0, currency: currency),
            Money(minorUnits: amounts.1, currency: currency),
            Money(minorUnits: amounts.2, currency: currency)
        )
    },
    seed: PropertySeed.additive,
    edges: [
        triple(Money(minorUnits: 0, currency: .gbp), Money(minorUnits: 0, currency: .gbp), Money(minorUnits: 0, currency: .gbp)),
        triple(Money(minorUnits: 1, currency: .jpy), Money(minorUnits: -1, currency: .jpy), Money(minorUnits: 0, currency: .jpy)),
    ]
)

// Ordered pairs of distinct currencies, so `lhs + rhs` always mismatches. The amounts are generated;
// only the clash of currencies matters.
private let mismatchCurrencyPairs: [(Currency, Currency)] = [(.gbp, .eur), (.eur, .usd), (.usd, .jpy), (.jpy, .gbp)]

private let mismatchPairs: [MismatchPair] = samples(
    zip(
        Gen<(Currency, Currency)>.element(of: mismatchCurrencyPairs),
        zip(Gen<Int64>.int(in: additiveAmountRange), Gen<Int64>.int(in: additiveAmountRange))
    ).map { currencies, amounts in
        MismatchPair(
            lhs: Money(minorUnits: amounts.0, currency: currencies.0),
            rhs: Money(minorUnits: amounts.1, currency: currencies.1)
        )
    },
    seed: PropertySeed.additive
)

@Suite("MoneyOf additive-group properties")
struct MoneyAdditivePropertyTests {

    @Test("Typed addition is commutative", arguments: typedTriples)
    private func typedCommutativity(_ triple: AdditiveTriple<GBP>) {
        #expect(triple.a + triple.b == triple.b + triple.a)
    }

    @Test("Typed addition is associative", arguments: typedTriples)
    private func typedAssociativity(_ triple: AdditiveTriple<GBP>) {
        #expect((triple.a + triple.b) + triple.c == triple.a + (triple.b + triple.c))
    }

    @Test("Zero is the typed additive identity", arguments: typedTriples)
    private func typedIdentity(_ triple: AdditiveTriple<GBP>) {
        #expect(triple.a + .zero == triple.a)
    }

    @Test("A typed amount less itself, and plus its negation, is zero", arguments: typedTriples)
    private func typedInverse(_ triple: AdditiveTriple<GBP>) {
        #expect(triple.a - triple.a == .zero)
        #expect(triple.a + (-triple.a) == .zero)
    }

    @Test("Typed subtraction cancels addition", arguments: typedTriples)
    private func typedCancellation(_ triple: AdditiveTriple<GBP>) {
        #expect((triple.a + triple.b) - triple.b == triple.a)
    }

    @Test("Runtime addition is commutative", arguments: runtimeTriples)
    private func runtimeCommutativity(_ triple: AdditiveTriple<Money>) throws {
        #expect(try (triple.a + triple.b) == (triple.b + triple.a))
    }

    @Test("Runtime addition is associative", arguments: runtimeTriples)
    private func runtimeAssociativity(_ triple: AdditiveTriple<Money>) throws {
        #expect(try ((triple.a + triple.b) + triple.c) == (triple.a + (triple.b + triple.c)))
    }

    @Test("Zero is the runtime additive identity", arguments: runtimeTriples)
    private func runtimeIdentity(_ triple: AdditiveTriple<Money>) throws {
        let zero = Money(minorUnits: 0, currency: triple.a.currency)

        #expect(try (triple.a + zero) == triple.a)
    }

    @Test("A runtime amount less itself, and plus its negation, is zero", arguments: runtimeTriples)
    private func runtimeInverse(_ triple: AdditiveTriple<Money>) throws {
        let zero = Money(minorUnits: 0, currency: triple.a.currency)

        #expect(try (triple.a - triple.a) == zero)
        #expect(try (triple.a + (-triple.a)) == zero)
    }

    @Test("Runtime subtraction cancels addition", arguments: runtimeTriples)
    private func runtimeCancellation(_ triple: AdditiveTriple<Money>) throws {
        #expect(try ((triple.a + triple.b) - triple.b) == triple.a)
    }

    @Test("Adding across currencies throws a mismatch", arguments: mismatchPairs)
    private func crossCurrencyThrows(_ pair: MismatchPair) {
        #expect(throws: MoneyError.self) {
            try pair.lhs + pair.rhs
        }
    }
}
