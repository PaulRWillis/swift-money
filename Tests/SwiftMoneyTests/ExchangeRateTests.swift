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

    @Test("A quoted pair of minor units builds the rate")
    func quotingBuilds() throws {
        let rate = try #require(Rate(string: "0.87"))
        let quoted = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(quoting: 87, per: 100))
        let direct = try #require(ExchangeRate<Currencies.EUR, Currencies.GBP>(rate))

        #expect(quoted == direct)
    }

    @Test("A quote per zero is not representable")
    func quotingPerZeroIsNil() {
        #expect(ExchangeRate<Currencies.EUR, Currencies.GBP>(quoting: 87, per: 0) == nil)
    }

    @Test("A quote of a non-positive amount is not representable")
    func quotingNonPositiveIsNil() {
        #expect(ExchangeRate<Currencies.EUR, Currencies.GBP>(quoting: 0, per: 100) == nil)
        #expect(ExchangeRate<Currencies.EUR, Currencies.GBP>(quoting: -87, per: 100) == nil)
    }
}
