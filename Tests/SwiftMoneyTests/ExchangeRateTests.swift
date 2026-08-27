import SwiftMoney
import Testing

@Suite("Exchange Rate Tests")
struct ExchangeRateTests {

    @Test("A positive rate builds")
    func positiveRateBuilds() throws {
        let rate = try #require(Rate(string: "0.8765262907"))

        #expect(ExchangeRate<Currencies.EUR, Currencies.GBP>(rate) != nil)
    }

    @Test("A zero or negative rate is not an exchange rate")
    func nonPositiveIsNil() {
        #expect(ExchangeRate<Currencies.EUR, Currencies.GBP>(.percent(0)) == nil)
        #expect(ExchangeRate<Currencies.EUR, Currencies.GBP>(.percent(-1)) == nil)
    }

    @Test("Applying a margin takes the spread off the mid rate")
    func applyingMargin() throws {
        let midRate = try #require(Rate(string: "1"))
        let mid = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(midRate))
        let margin = try #require(Margin(.basisPoints(5)))                                             // 0.0005
        let expectedRate = try #require(Rate(string: "0.9995"))

        let customer = mid.applyingMargin(margin)
        let expected = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(expectedRate))

        #expect(customer == expected)
    }

    @Test("A zero margin leaves the rate unchanged")
    func zeroMarginIsIdentity() throws {
        let midRate = try #require(Rate(string: "0.87"))
        let mid = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(midRate))
        let noMargin = try #require(Margin(.percent(0)))

        #expect(mid.applyingMargin(noMargin) == mid)
    }

    @Test("Crossing two rates composes them through the shared currency")
    func crossing() throws {
        let eurUsdRate = try #require(Rate(string: "1.1"))
        let usdGbpRate = try #require(Rate(string: "0.8"))
        let expectedRate = try #require(Rate(string: "0.88"))

        let eurUsd = try #require(ExchangeRate<Currencies.EUR, Currencies.USD>(eurUsdRate))
        let usdGbp = try #require(ExchangeRate<Currencies.USD, Currencies.GBP>(usdGbpRate))

        let eurGbp = eurUsd.crossed(with: usdGbp)
        let expected = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(expectedRate))

        #expect(eurGbp == expected)
    }
}
