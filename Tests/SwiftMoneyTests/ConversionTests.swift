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

    @Test("Converting an unrounded amount keeps the whole chain unsettled")
    func convertsAnUnroundedAmount() throws {
        let eurGbp = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(quoting: 87, per: 100))
        let third = try #require(Rate(string: "1/3"))

        let gbp = (EUR(minorUnits: 300_00).unrounded * third).converted(using: eurGbp).rounded(.toNearestOrEven)

        #expect(gbp == GBP(minorUnits: 87_00))   // 300.00 × 1/3 = 100.00 EUR, × 0.87 = 87.00 GBP
    }
}
