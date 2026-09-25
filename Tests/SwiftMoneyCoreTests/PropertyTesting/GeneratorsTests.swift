import SwiftMoneyCore
import Testing

@Suite("Domain generators")
struct GeneratorsTests {

    private static let count = PropertySeed.sampleCount
    private static let seed: UInt64 = 99

    // Ranges used only to exercise the generators here; the suites pass their own overflow-safe bounds.
    private static let amountRange: ClosedRange<Int64> = -1_000 ... 1_000
    private static let partCountRange: ClosedRange<Int64> = 1 ... 1_000
    private static let weightRange: ClosedRange<Int64> = 0 ... 1_000
    private static let weightCountRange: ClosedRange<Int64> = 1 ... 20
    private static let rateSignificandRange: ClosedRange<Int64> = 0 ... 1_000_000

    @Test("Typed amounts stay within their range")
    func typedAmountsInRange() {
        let low = GBP(minorUnits: Self.amountRange.lowerBound)
        let high = GBP(minorUnits: Self.amountRange.upperBound)

        for amount in samples(.typedMoney(minorUnitsIn: Self.amountRange), count: Self.count, seed: Self.seed) {
            #expect(amount >= low)
            #expect(amount <= high)
        }
    }

    @Test("Runtime amounts stay within their range and currency set")
    func runtimeAmountsInRange() throws {
        let currencies: [Currency] = [.gbp, .eur, .usd, .jpy]

        for amount in samples(
            .runtimeMoney(minorUnitsIn: Self.amountRange, currency: .isoCurrency),
            count: Self.count,
            seed: Self.seed
        ) {
            #expect(currencies.contains(amount.currency))

            let low = Money(minorUnits: Self.amountRange.lowerBound, currency: amount.currency)
            let high = Money(minorUnits: Self.amountRange.upperBound, currency: amount.currency)
            #expect(try amount.isLessThan(low) == false)   // amount >= low
            #expect(try high.isLessThan(amount) == false)   // amount <= high
        }
    }

    @Test("Custom-scale currencies build without failing")
    func customCurrenciesBuild() {
        let codes: Set<CurrencyCode> = ["KHO", "PTS", "GEM"]

        var generator = Seed(Self.seed)
        for _ in 0 ..< Self.count {
            let currency = Gen<Currency>.customScaleCurrency.run(&generator)
            #expect(codes.contains(currency.code))
        }
    }

    @Test("Part counts stay within their range")
    func partCountsInRange() {
        for parts in samples(.partCount(in: Self.partCountRange), count: Self.count, seed: Self.seed) {
            #expect(Int(parts) >= Int(Self.partCountRange.lowerBound))
            #expect(Int(parts) <= Int(Self.partCountRange.upperBound))
        }
    }

    @Test("Weight lists are valid weights with a positive member")
    func weightListsAreValid() {
        for list in samples(
            .weightList(countIn: Self.weightCountRange, weightIn: Self.weightRange),
            count: Self.count,
            seed: Self.seed
        ) {
            #expect(list.isEmpty == false)
            #expect(list.count <= Int(Self.weightCountRange.upperBound))
            #expect(list.allSatisfy { Int($0) >= 0 && Int($0) <= Int(Self.weightRange.upperBound) })
            #expect(list.contains { Int($0) > 0 })
            // The two conditions above are exactly what `Weights.init` requires, so it never returns nil.
            #expect(Weights(list) != nil)
        }
    }

    @Test("Generated rates are never negative")
    func ratesAreNonNegative() {
        for rate in samples(
            .rate(significandIn: Self.rateSignificandRange, denominators: Gen<Rate>.decimalDenominators),
            count: Self.count,
            seed: Self.seed
        ) {
            #expect(rate.basisPoints(rounding: .towardZero) >= 0)
        }
    }

    @Test("samples prepends the edge corpus, then the random draws")
    func samplesPrependsEdges() {
        let edges = [GBP(minorUnits: 0), GBP(minorUnits: 1)]
        let drawCount = 5

        let result = samples(
            .typedMoney(minorUnitsIn: Self.amountRange),
            count: drawCount,
            seed: Self.seed,
            edges: edges
        )

        #expect(result.count == edges.count + drawCount)
        #expect(Array(result.prefix(edges.count)) == edges)
    }

    @Test("The same seed yields the same corpus")
    func corpusIsDeterministic() {
        let first = samples(.typedMoney(minorUnitsIn: Self.amountRange), count: Self.count, seed: Self.seed)
        let second = samples(.typedMoney(minorUnitsIn: Self.amountRange), count: Self.count, seed: Self.seed)

        #expect(first == second)
    }
}
