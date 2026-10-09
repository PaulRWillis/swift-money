import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

private typealias EURGBP = FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>

// Eighteen decimal places, as ether has, so a rate from it holds only a couple of places per coin.
private let ether = customCurrency(code: "ETH", unitScale: 1_000_000_000_000_000_000)

// The coarsest and finest scales, far enough apart that rescaling a quote between them overflows.
private let lowPrecision = customCurrency(code: "LOW", unitScale: 1)
private let highPrecision = customCurrency(code: "HGH", unitScale: 1_000_000_000_000_000_000)

private enum Ether: CurrencyType {
    static let currency = ether
}

@Suite("Runtime exchange rate")
struct RuntimeExchangeRateTests {

    @Test("A positive quote builds a rate between the two currencies it names")
    func builds() throws {
        let rate = try #require(FX.ExchangeRate("0.87", from: .eur, to: .gbp))

        #expect(rate.from == .eur)
        #expect(rate.to == .gbp)
        #expect(rate.description == "0.87")
    }

    @Test("A typed rate names the currencies of its type")
    func typedRateNamesItsCurrencies() throws {
        let rate = try #require(EURGBP("0.87"))

        #expect(rate.from == .eur)
        #expect(rate.to == .gbp)
    }

    @Test("A rate from a currency to itself builds")
    func buildsBetweenOneCurrency() throws {
        let rate = try #require(FX.ExchangeRate("1", from: .gbp, to: .gbp))

        #expect(rate.from == .gbp)
        #expect(rate.to == .gbp)
        #expect(try FX.ExchangeRate(string: "1", from: .gbp, to: .gbp) == rate)
    }

    @Test("A rate builds between custom currencies at their own scales")
    func buildsForCustomCurrencies() throws {
        let ethGbp = try FX.ExchangeRate(string: "3200.12", from: ether, to: .gbp)

        #expect(ethGbp.from == ether)
        #expect(ethGbp.description == "3200.12")
        #expect(FX.ExchangeRate("3200.12", from: ether, to: .gbp) == ethGbp)
    }

    @Test("A zero or negative quote builds no rate")
    func nonPositiveIsNil() {
        #expect(FX.ExchangeRate(.percent(0), from: .eur, to: .gbp) == nil)
        #expect(FX.ExchangeRate(.percent(-1), from: .eur, to: .gbp) == nil)
    }

    @Test("A quote with more places than the pair holds builds no rate, rather than a rounded one")
    func inexactQuoteIsNil() {
        #expect(FX.ExchangeRate("3200.12", from: ether, to: .gbp) != nil)
        #expect(FX.ExchangeRate("3200.125", from: ether, to: .gbp) == nil)
    }

    @Test("A quote that overflows once rescaled between very different scales builds no rate")
    func extremeScaleDifferenceIsNil() {
        #expect(FX.ExchangeRate("1000", from: lowPrecision, to: highPrecision) == nil)
        #expect(throws: FX.ExchangeRateParsingError.overflow) {
            try FX.ExchangeRate(string: "1000", from: lowPrecision, to: highPrecision)
        }
    }

    @Test("A rate between currencies of different scales holds the quote its typed form holds")
    func acrossScalesMatchesTheTypedRate() throws {
        let typed = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>("149.5"))
        let runtime = try #require(FX.ExchangeRate("149.5", from: .usd, to: .jpy))

        #expect(runtime == FX.ExchangeRate(typed))
        #expect(runtime.description == "149.5")
    }

    @Test("Text that is not a plain decimal is refused", arguments: ["abc", "", ".", "-", "1/3", "5%", "1e3", "0.8.7"])
    func refusesText(_ text: String) {
        #expect(throws: FX.ExchangeRateParsingError.unrecognizedText) {
            try FX.ExchangeRate(string: text, from: .eur, to: .gbp)
        }
    }

    @Test("A quote of zero or less is refused", arguments: ["0", "0.000", "-0.87"])
    func refusesANonPositiveQuote(_ text: String) {
        #expect(throws: FX.ExchangeRateParsingError.notPositive) {
            try FX.ExchangeRate(string: text, from: .eur, to: .gbp)
        }
    }

    @Test("A quote too large to hold is refused")
    func refusesAnOverlargeQuote() {
        #expect(throws: FX.ExchangeRateParsingError.overflow) {
            try FX.ExchangeRate(string: "1000000000000000000000", from: .eur, to: .gbp)
        }
    }

    // A rate holds eighteen places of `to` smallest units per `from` smallest unit, so a quote per
    // major unit holds eighteen plus `to`'s places less `from`'s.
    @Test("How many places a quote may have depends on the two currencies' scales")
    func placesDependOnTheScales() throws {
        _ = try FX.ExchangeRate(string: "149.1234567890123456", from: .usd, to: .jpy)
        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 16)) {
            try FX.ExchangeRate(string: "149.12345678901234567", from: .usd, to: .jpy)
        }

        _ = try FX.ExchangeRate(string: "0.00668896321070234114", from: .jpy, to: .usd)
        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 20)) {
            try FX.ExchangeRate(string: "0.006688963210702341145", from: .jpy, to: .usd)
        }

        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 2)) {
            try FX.ExchangeRate(string: "3200.125", from: ether, to: .gbp)
        }

        _ = try FX.ExchangeRate(string: "0.0003125123456789012345678901234567", from: .gbp, to: ether)
        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 34)) {
            try FX.ExchangeRate(string: "0.00031251234567890123456789012345678", from: .gbp, to: ether)
        }
    }

    @Test("Applying a margin takes the spread off the mid rate and keeps the pair")
    func applyingMargin() throws {
        let mid = try #require(FX.ExchangeRate("1.5", from: .eur, to: .gbp))
        let margin = try #require(FX.Margin(.percent(20)))
        let expected = try #require(FX.ExchangeRate("1.2", from: .eur, to: .gbp))

        #expect(try mid.applyingMargin(margin) == expected)
    }

    @Test("A margin that would round the customer rate to zero throws")
    func marginRoundingToZeroThrows() throws {
        let mid = try #require(FX.ExchangeRate("0.000000000000000001", from: .eur, to: .gbp))
        let margin = try #require(FX.Margin(.percent(60)))

        #expect(throws: FX.ExchangeError<Currency>.roundsToZero) {
            try mid.applyingMargin(margin)
        }
    }

    @Test("Inverting a rate gives the rate the other way, between the same currencies swapped")
    func inverting() throws {
        let usdJpy = try #require(FX.ExchangeRate("125", from: .usd, to: .jpy))
        let expected = try #require(FX.ExchangeRate("0.008", from: .jpy, to: .usd))

        #expect(try usdJpy.inverted() == expected)
    }

    // ¥1 = $10¹⁷ is 10¹⁹ cents a yen, whose inverse, 10⁻¹⁹ yen a cent, is a tenth of the smallest step.
    @Test("Inverting a rate whose inverse rounds to zero throws")
    func invertingToZeroThrows() throws {
        let huge = try #require(FX.ExchangeRate("100000000000000000", from: .jpy, to: .usd))

        #expect(throws: FX.ExchangeError<Currency>.roundsToZero) {
            try huge.inverted()
        }
    }

    @Test("Rates with the same quote between different pairs are not equal")
    func sameQuoteDifferentPairIsUnequal() throws {
        let eurGbp = try #require(FX.ExchangeRate("0.87", from: .eur, to: .gbp))
        let eurUsd = try #require(FX.ExchangeRate("0.87", from: .eur, to: .usd))
        let gbpEur = try #require(FX.ExchangeRate("0.87", from: .gbp, to: .eur))

        #expect(eurGbp != eurUsd)
        #expect(eurGbp != gbpEur)
        #expect(Set([eurGbp, eurUsd, gbpEur, eurGbp]).count == 3)
    }

    // 1 KHO at two places and 10 KHO at three are both one pence per smallest unit.
    @Test("A rate from one code at two scales is two different rates, even when the stored rate matches")
    func oneCodeAtTwoScalesIsUnequal() throws {
        let hundredths = customCurrency(code: "KHO", unitScale: 100)
        let thousandths = customCurrency(code: "KHO", unitScale: 1_000)
        let coarse = try #require(FX.ExchangeRate("1", from: hundredths, to: .gbp))
        let fine = try #require(FX.ExchangeRate("10", from: thousandths, to: .gbp))

        #expect(coarse != fine)
        #expect(Set([coarse, fine]).count == 2)
    }

    @Test("A typed rate becomes a runtime rate between the same currencies, at the same quote")
    func erasure() throws {
        let typed = try #require(EURGBP("0.87"))
        let runtime = FX.ExchangeRate(typed)

        #expect(runtime.from == .eur)
        #expect(runtime.to == .gbp)
        #expect(runtime == FX.ExchangeRate("0.87", from: .eur, to: .gbp))
    }

    @Test("A typed custom-currency rate keeps its currency's scale as a runtime rate")
    func erasureKeepsACustomScale() throws {
        let typed = try FX.ExchangeRateOf<Ether, Currencies.GBP>(string: "3200.12")

        #expect(FX.ExchangeRate(typed) == (try FX.ExchangeRate(string: "3200.12", from: ether, to: .gbp)))
    }

    @Test("A runtime rate between a type's currencies becomes that typed rate")
    func runtimeToTyped() throws {
        let runtime = try #require(FX.ExchangeRate("0.87", from: .eur, to: .gbp))

        #expect(try EURGBP(runtime) == EURGBP("0.87"))
    }

    @Test("A runtime rate from another currency is refused, naming the currency the type needs first")
    func runtimeToTypedFromMismatch() throws {
        let usdGbp = try #require(FX.ExchangeRate("0.75", from: .usd, to: .gbp))

        #expect(throws: MoneyError.currencyMismatch(lhs: .eur, rhs: .usd)) {
            try EURGBP(usdGbp)
        }
    }

    @Test("A runtime rate to another currency is refused, naming the currency the type needs first")
    func runtimeToTypedToMismatch() throws {
        let eurUsd = try #require(FX.ExchangeRate("1.1", from: .eur, to: .usd))

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .usd)) {
            try EURGBP(eurUsd)
        }
    }

    @Test("A runtime rate wrong on both sides reports the side it converts from")
    func runtimeToTypedBothMismatchReportsFrom() throws {
        let usdJpy = try #require(FX.ExchangeRate("149.5", from: .usd, to: .jpy))

        #expect(throws: MoneyError.currencyMismatch(lhs: .eur, rhs: .usd)) {
            try EURGBP(usdJpy)
        }
    }

    @Test("A runtime rate whose code matches at another scale is refused")
    func runtimeToTypedScaleMismatch() throws {
        let coarseEther = customCurrency(code: "ETH", unitScale: 100)
        let runtime = try #require(FX.ExchangeRate("3200.12", from: coarseEther, to: .gbp))

        #expect(throws: MoneyError.currencyMismatch(lhs: ether, rhs: coarseEther)) {
            try FX.ExchangeRateOf<Ether, Currencies.GBP>(runtime)
        }
    }

    @Test("Erasing a typed rate commutes with inverting, applying a margin and describing it")
    func erasureCommutes() throws {
        let typed = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>("149.5"))
        let margin = try #require(FX.Margin(.basisPoints(5)))

        #expect(FX.ExchangeRate(try typed.inverted()) == (try FX.ExchangeRate(typed).inverted()))
        #expect(FX.ExchangeRate(try typed.applyingMargin(margin)) == (try FX.ExchangeRate(typed).applyingMargin(margin)))
        #expect(FX.ExchangeRate(typed).description == typed.description)
    }
}
