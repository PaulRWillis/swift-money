import SwiftMoneyCore
import Testing

private typealias EURGBP = FX.ExchangeRate<Currencies.EUR, Currencies.GBP>

// Eighteen decimal places, as ether has, so a rate from it holds only a few places per coin.
private enum Ether: CurrencyType {
    static let currency = customCurrency(code: "ETH", unitScale: 1_000_000_000_000_000_000)
}

@Suite("Exchange Rate Parsing Tests")
struct ExchangeRateParsingTests {

    @Test("A decimal quote builds the same rate as the quote given as a rate")
    func parses() throws {
        let rate = try #require(EURGBP("0.87"))

        #expect(try EURGBP(string: "0.87") == rate)
    }

    @Test("Text that is not a plain decimal is refused", arguments: ["abc", "", ".", "-", "1/3", "5%", "1e3", "0.8.7"])
    func refusesText(_ text: String) {
        #expect(throws: FX.ExchangeRateParsingError.unrecognizedText) {
            try EURGBP(string: text)
        }
    }

    @Test("A quote of zero or less is refused", arguments: ["0", "0.000", "-0.87"])
    func refusesANonPositiveQuote(_ text: String) {
        #expect(throws: FX.ExchangeRateParsingError.notPositive) {
            try EURGBP(string: text)
        }
    }

    @Test("A quote with more places than the rate holds is refused, naming the most it holds")
    func refusesAnInexactQuote() {
        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 18)) {
            try EURGBP(string: "0.8765262907123456789")
        }
    }

    // Past about forty places the digits can't even be scaled down to the rate's last place.
    @Test("A quote far finer than the rate holds is refused as inexact, not as too large")
    func refusesAFarFinerQuoteAsInexact() {
        let text = "0." + String(repeating: "0", count: 60) + "1"

        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 18)) {
            try EURGBP(string: text)
        }
    }

    @Test("Zeros past the places the rate holds lose nothing, so the quote reads")
    func readsTrailingZeros() throws {
        let rate = try #require(EURGBP("0.87"))

        #expect(try EURGBP(string: "0.870000000000000000000") == rate)
    }

    @Test("A quote too large to hold is refused")
    func refusesAnOverlargeQuote() {
        #expect(throws: FX.ExchangeRateParsingError.overflow) {
            try EURGBP(string: "1000000000000000000000")
        }
    }

    // A rate holds eighteen places of `To` smallest units per `From` smallest unit, so a quote per
    // major unit holds eighteen plus `To`'s places less `From`'s.
    @Test("How many places a quote may have depends on the two currencies' scales")
    func placesDependOnTheScales() throws {
        _ = try FX.ExchangeRate<Currencies.USD, Currencies.JPY>(string: "149.1234567890123456")
        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 16)) {
            try FX.ExchangeRate<Currencies.USD, Currencies.JPY>(string: "149.12345678901234567")
        }

        _ = try FX.ExchangeRate<Currencies.JPY, Currencies.USD>(string: "0.00668896321070234114")
        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 20)) {
            try FX.ExchangeRate<Currencies.JPY, Currencies.USD>(string: "0.006688963210702341145")
        }

        _ = try FX.ExchangeRate<Ether, Currencies.GBP>(string: "3200.12")
        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 2)) {
            try FX.ExchangeRate<Ether, Currencies.GBP>(string: "3200.125")
        }

        _ = try FX.ExchangeRate<Currencies.GBP, Ether>(string: "0.0003125123456789012345678901234567")
        #expect(throws: FX.ExchangeRateParsingError.inexactRate(maximumFractionDigits: 34)) {
            try FX.ExchangeRate<Currencies.GBP, Ether>(string: "0.00031251234567890123456789012345678")
        }
    }

    @Test("A rate is described by its market quote, with no trailing zeros")
    func describes() throws {
        let eurGbp = try #require(EURGBP("0.87"))
        let whole = try #require(EURGBP("2"))
        let usdJpy = try #require(FX.ExchangeRate<Currencies.USD, Currencies.JPY>("149.5"))
        let jpyUsd = try #require(FX.ExchangeRate<Currencies.JPY, Currencies.USD>("0.008"))

        #expect(eurGbp.description == "0.87")
        #expect(whole.description == "2")
        #expect(usdJpy.description == "149.5")
        #expect(jpyUsd.description == "0.008")
    }

    // ¥1 = $0.0066889632107023411… needs more than eighteen places once quoted per major unit.
    @Test("A rate whose quote needs more than eighteen places is described with every digit")
    func describesBeyondEighteenPlaces() throws {
        let jpyUsd = try #require(FX.ExchangeRate<Currencies.USD, Currencies.JPY>("149.5")).inverted()

        #expect(jpyUsd.description == "0.00668896321070234114")
        #expect(try FX.ExchangeRate<Currencies.JPY, Currencies.USD>(string: jpyUsd.description) == jpyUsd)
    }
}
