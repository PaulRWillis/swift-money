import SwiftMoney
import Testing

@Suite("Conversion Tests")
struct ConversionTests {

    @Test("An amount converts into the target currency")
    func convertsIntoTargetCurrency() throws {
        let eurGbp = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(quoting: 87, per: 100))

        let gbp = EUR(minorUnits: 100_00).converted(using: eurGbp).rounded(.toNearestOrEven)

        #expect(gbp == GBP(minorUnits: 87_00))
    }

    @Test("Converting keeps the fraction for a single settling")
    func convertingRoundsOnce() throws {
        let rate = try #require(Rate(string: "0.8765262907"))
        let eurGbp = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(rate))

        // 100.00 EUR × 0.8765262907 = 87.65262907 GBP, settled once to 87.65.
        let gbp = EUR(minorUnits: 100_00).converted(using: eurGbp).rounded(.toNearestOrEven)

        #expect(gbp == GBP(minorUnits: 87_65))
    }

    @Test("Applying a margin gives the customer less than the mid rate")
    func marginReducesTheCustomerAmount() throws {
        let rate = try #require(Rate(string: "0.8765262907"))
        let eurGbp = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(rate))
        let margin = try #require(Margin(.basisPoints(5)))

        let mid = EUR(minorUnits: 100_00).converted(using: eurGbp).rounded(.toNearestOrEven)
        let customer = EUR(minorUnits: 100_00).converted(using: eurGbp.applyingMargin(margin)).rounded(.toNearestOrEven)

        #expect(customer < mid)
    }

    // The whole chain to an exact figure: a mid rate of 1.5 less a 20% margin is 1.2, so £1.00 converts
    // to exactly €1.20. Guards the rate and the conversion together, not each on its own.
    @Test("Applying a margin then converting gives the exact amount")
    func marginThenConvertIsExact() throws {
        let midRate = try #require(Rate(string: "1.5"))
        let mid = try #require(ExchangeRate<Currencies.GBP, Currencies.EUR>(midRate))
        let margin = try #require(Margin(.percent(20)))

        let euros = GBP(minorUnits: 1_00).converted(using: mid.applyingMargin(margin)).rounded(.toNearestOrEven)

        #expect(euros == EUR(minorUnits: 1_20))
    }

    @Test("A multi-hop conversion via a cross rate matches the direct cross rate")
    func multiHopMatchesCrossRate() throws {
        let eurUsdRate = try #require(Rate(string: "1.1"))
        let usdGbpRate = try #require(Rate(string: "0.8"))
        let eurUsd = try #require(ExchangeRate<Currencies.EUR, Currencies.USD>(eurUsdRate))
        let usdGbp = try #require(ExchangeRate<Currencies.USD, Currencies.GBP>(usdGbpRate))
        let directRate = try #require(Rate(string: "0.88"))
        let eurGbp = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(directRate))

        let viaCross = EUR(minorUnits: 100_00).converted(using: eurUsd.crossed(with: usdGbp)).rounded(.toNearestOrEven)
        let direct = EUR(minorUnits: 100_00).converted(using: eurGbp).rounded(.toNearestOrEven)

        #expect(viaCross == direct)
        #expect(viaCross == GBP(minorUnits: 88_00))
    }

    // Each leg carries its own margin, as a provider takes a spread on every hop, then the two compose.
    // EUR→USD 1.25 less 20% is 1.0; USD→GBP 1.5 less 20% is 1.2; crossed that is 1.2, so €100.00 is
    // £120.00 exactly. Guards crossing and per-leg margins together, end to end.
    @Test("Crossing two rates that each carry a margin gives the exact amount")
    func crossingWithMarginsIsExact() throws {
        let eurUsdRate = try #require(Rate(string: "1.25"))
        let usdGbpRate = try #require(Rate(string: "1.5"))
        let margin = try #require(Margin(.percent(20)))

        let eurUsd = try #require(ExchangeRate<Currencies.EUR, Currencies.USD>(eurUsdRate)).applyingMargin(margin)
        let usdGbp = try #require(ExchangeRate<Currencies.USD, Currencies.GBP>(usdGbpRate)).applyingMargin(margin)

        let gbp = EUR(minorUnits: 100_00).converted(using: eurUsd.crossed(with: usdGbp)).rounded(.toNearestOrEven)

        #expect(gbp == GBP(minorUnits: 120_00))
    }

    @Test("Converting an unrounded amount keeps the whole chain unsettled")
    func convertsAnUnroundedAmount() throws {
        let eurGbp = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(quoting: 87, per: 100))
        let third = try #require(Rate(string: "1/3"))

        let gbp = (EUR(minorUnits: 300_00).unrounded * third).converted(using: eurGbp).rounded(.toNearestOrEven)

        #expect(gbp == GBP(minorUnits: 87_00))   // 300.00 × 1/3 = 100.00 EUR, × 0.87 = 87.00 GBP
    }

    // USD has 100 minor units, JPY has 1. A market rate is quoted per major unit ($1 = ¥149.5), so
    // converting must account for the differing scales: $1.00 is ¥150 (rounded), not ¥14,950.
    @Test("A market rate converts correctly across currencies of different scale")
    func convertsAcrossDifferentScales() throws {
        let rate = try #require(Rate(string: "149.5"))               // $1 = ¥149.5, quoted per major unit
        let usdJpy = try #require(ExchangeRate<Currencies.USD, Currencies.JPY>(rate))

        let yen = USD(minorUnits: 1_00).converted(using: usdJpy).rounded(.toNearestOrEven)

        #expect(yen == JPY(minorUnits: 150))   // ¥149.5 → ¥150, not ¥14,950
    }

    // The quoting: initialiser is minor-per-minor, so it needs no scale adjustment: 100 US cents are
    // worth 150 yen directly.
    @Test("A minor-unit quote converts across different scales")
    func quotedMinorUnitsAcrossScales() throws {
        let usdJpy = try #require(ExchangeRate<Currencies.USD, Currencies.JPY>(quoting: 150, per: 1_00))

        let yen = USD(minorUnits: 1_00).converted(using: usdJpy).rounded(.toNearestOrEven)

        #expect(yen == JPY(minorUnits: 150))
    }
}
