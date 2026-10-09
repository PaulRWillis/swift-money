import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

@Suite("Runtime exchange rate crossing")
struct RuntimeExchangeRateCrossingTests {

    @Test("Crossing two rates composes them through the shared currency")
    func crossing() throws {
        let eurUsd = try #require(FX.ExchangeRate("1.1", from: .eur, to: .usd))
        let usdGbp = try #require(FX.ExchangeRate("0.8", from: .usd, to: .gbp))
        let expected = try #require(FX.ExchangeRate("0.88", from: .eur, to: .gbp))

        #expect(try eurUsd.crossed(with: usdGbp) == expected)
    }

    @Test("Crossing with a rate that does not start where this one ends throws, with its currency")
    func crossingMismatchThrows() throws {
        let eurUsd = try #require(FX.ExchangeRate("1.1", from: .eur, to: .usd))
        let gbpJpy = try #require(FX.ExchangeRate("190", from: .gbp, to: .jpy))

        #expect(throws: FX.ExchangeError<Currency>.currencyMismatch(.gbp)) {
            try eurUsd.crossed(with: gbpJpy)
        }
    }

    @Test("Crossing through one code at two scales is a mismatch")
    func crossingScaleMismatchThrows() throws {
        let hundredths = customCurrency(code: "KHO", unitScale: 100)
        let thousandths = customCurrency(code: "KHO", unitScale: 1_000)
        let gbpKho = try #require(FX.ExchangeRate("2", from: .gbp, to: hundredths))
        let khoEur = try #require(FX.ExchangeRate("0.5", from: thousandths, to: .eur))

        #expect(throws: FX.ExchangeError<Currency>.currencyMismatch(thousandths)) {
            try gbpKho.crossed(with: khoEur)
        }
    }

    @Test("Crossing two rates whose product is too large throws")
    func crossingOverflowThrows() throws {
        let eurUsd = try #require(FX.ExchangeRate("1000000000000", from: .eur, to: .usd))
        let usdGbp = try #require(FX.ExchangeRate("1000000000000", from: .usd, to: .gbp))

        #expect(throws: FX.ExchangeError<Currency>.overflow) {
            try eurUsd.crossed(with: usdGbp)
        }
    }

    @Test("Crossing two rates whose product rounds to zero throws")
    func crossingToZeroThrows() throws {
        let eurUsd = try #require(FX.ExchangeRate("0.0000000001", from: .eur, to: .usd))
        let usdGbp = try #require(FX.ExchangeRate("0.0000000001", from: .usd, to: .gbp))

        #expect(throws: FX.ExchangeError<Currency>.roundsToZero) {
            try eurUsd.crossed(with: usdGbp)
        }
    }

    @Test("Crossing rates that both mismatch and overflow reports the mismatch")
    func crossingMismatchWinsOverOverflow() throws {
        let eurUsd = try #require(FX.ExchangeRate("1000000000000", from: .eur, to: .usd))
        let gbpJpy = try #require(FX.ExchangeRate("1000000000000", from: .gbp, to: .jpy))

        #expect(throws: FX.ExchangeError<Currency>.currencyMismatch(.gbp)) {
            try eurUsd.crossed(with: gbpJpy)
        }
    }

    @Test("Erasing typed rates commutes with crossing them, across scales")
    func erasureCommutesWithCrossing() throws {
        let usdJpy = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>("149.5"))
        let jpyEur = try #require(FX.ExchangeRateOf<Currencies.JPY, Currencies.EUR>("0.0061"))

        #expect(
            FX.ExchangeRate(try usdJpy.crossed(with: jpyEur))
                == (try FX.ExchangeRate(usdJpy).crossed(with: FX.ExchangeRate(jpyEur)))
        )
    }
}
