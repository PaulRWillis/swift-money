import Foundation
import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

// Market quotes from 10⁻⁶ to 10¹², on grids of zero to six places.
private let codingRates: [Rate] = samples(
    Gen<Rate>.rate(significandIn: 1 ... 1_000_000_000_000, denominators: Gen<Rate>.decimalDenominators),
    seed: PropertySeed.exchangeRateCoding,
    edges: ["0.000001", "1", "1000000000000"]
)

private func roundTripped<From: CurrencyType, To: CurrencyType>(_ rate: FX.ExchangeRateOf<From, To>) throws -> FX.ExchangeRateOf<From, To> {
    try JSONDecoder().decode(FX.ExchangeRateOf<From, To>.self, from: JSONEncoder().encode(rate))
}

@Suite("Exchange-rate Codable properties")
struct ExchangeRateCodablePropertyTests {

    @Test("A rate reads back unchanged from what it writes, in either direction across scales", arguments: codingRates)
    private func roundTrips(_ quote: Rate) throws {
        let eurGbp = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(quote))
        let usdJpy = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>(quote))
        let jpyUsd = try #require(FX.ExchangeRateOf<Currencies.JPY, Currencies.USD>(quote))

        #expect(try roundTripped(eurGbp) == eurGbp)
        #expect(try roundTripped(usdJpy) == usdJpy)
        #expect(try roundTripped(jpyUsd) == jpyUsd)
    }

    // An inverse uses all eighteen places of the rate it keeps, which a major-unit quote can need
    // more than eighteen places to write.
    @Test("An inverted rate reads back unchanged from what it writes", arguments: codingRates)
    private func invertedRoundTrips(_ quote: Rate) throws {
        let usdJpy = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>(quote))
        let jpyUsd = try #require(FX.ExchangeRateOf<Currencies.JPY, Currencies.USD>(quote))

        let inverseOfUsdJpy = try usdJpy.inverted()
        let inverseOfJpyUsd = try jpyUsd.inverted()

        #expect(try roundTripped(inverseOfUsdJpy) == inverseOfUsdJpy)
        #expect(try roundTripped(inverseOfJpyUsd) == inverseOfJpyUsd)
    }
}
