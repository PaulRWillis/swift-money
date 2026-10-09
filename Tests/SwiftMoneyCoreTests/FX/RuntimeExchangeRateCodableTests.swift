import Foundation
import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

private typealias EURGBP = FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>

// Eighteen decimal places, as ether has: a currency the ISO table doesn't ship.
private let ether = customCurrency(code: "ETH", unitScale: 1_000_000_000_000_000_000)

private enum Ether: CurrencyType {
    static let currency = ether
}

// Keys are sorted because `JSONEncoder` does not otherwise fix their order.
private func json<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()

    encoder.outputFormatting = .sortedKeys

    return String(decoding: try encoder.encode(value), as: UTF8.self)
}

private func decoded<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
    try JSONDecoder().decode(type, from: Data(text.utf8))
}

/// Returns the context of the `dataCorrupted` error a decode throws.
///
/// - Parameters:
///   - type: The type to decode.
///   - text: The JSON to decode.
/// - Returns: The error's context, or `nil` after recording an issue when the error is another case.
/// - Throws: The expectation's failure when the decode throws nothing.
private func refusal<T: Decodable>(_ type: T.Type, from text: String) throws -> DecodingError.Context? {
    let error = #expect(throws: DecodingError.self) { _ = try decoded(type, from: text) }

    guard case let .dataCorrupted(context) = try #require(error) else {
        Issue.record("Expected a dataCorrupted error")

        return nil
    }

    return context
}

@Suite("Runtime exchange rate Codable")
struct RuntimeExchangeRateCodableTests {

    @Test("A runtime rate between ISO currencies is written as a typed one is, with no scales")
    func encodesISOCurrenciesWithoutScales() throws {
        let rate = try #require(FX.ExchangeRate("0.87", from: .eur, to: .gbp))

        #expect(try json(rate) == #"{"from":"EUR","rate":"0.87","to":"GBP"}"#)
    }

    @Test("A runtime rate between ISO currencies reads back from what it writes")
    func decodesISOCurrencies() throws {
        let rate = try #require(FX.ExchangeRate("149.5", from: .usd, to: .jpy))

        #expect(try decoded(FX.ExchangeRate.self, from: #"{"from":"USD","to":"JPY","rate":"149.5"}"#) == rate)
        #expect(try decoded(FX.ExchangeRate.self, from: json(rate)) == rate)
    }

    @Test("A custom currency is written with its scale, on whichever side it is")
    func encodesACustomCurrencyWithItsScale() throws {
        let ethGbp = try FX.ExchangeRate(string: "3200.12", from: ether, to: .gbp)
        let gbpEth = try ethGbp.inverted()

        #expect(try json(ethGbp) == #"{"from":"ETH","fromScale":18,"rate":"3200.12","to":"GBP"}"#)
        #expect(try json(gbpEth).contains(#""toScale":18"#))
        #expect(try json(gbpEth).contains("fromScale") == false)
    }

    @Test("A rate to or from a custom currency reads back from what it writes")
    func roundTripsACustomCurrency() throws {
        let ethGbp = try FX.ExchangeRate(string: "3200.12", from: ether, to: .gbp)
        let gbpEth = try ethGbp.inverted()

        #expect(try decoded(FX.ExchangeRate.self, from: json(ethGbp)) == ethGbp)
        #expect(try decoded(FX.ExchangeRate.self, from: json(gbpEth)) == gbpEth)
    }

    @Test("A typed custom-currency rate writes its scale, so it reads back as a runtime rate and as itself")
    func typedCustomReadsAsRuntime() throws {
        let typed = try FX.ExchangeRateOf<Ether, Currencies.GBP>(string: "3200.12")
        let text = try json(typed)

        #expect(text == #"{"from":"ETH","fromScale":18,"rate":"3200.12","to":"GBP"}"#)
        #expect(try decoded(FX.ExchangeRate.self, from: text) == FX.ExchangeRate(typed))
        #expect(try decoded(FX.ExchangeRateOf<Ether, Currencies.GBP>.self, from: text) == typed)
    }

    @Test("A runtime rate's JSON reads back as the typed rate between its currencies")
    func runtimeReadsAsTyped() throws {
        let runtime = try #require(FX.ExchangeRate("0.87", from: .eur, to: .gbp))

        #expect(try decoded(EURGBP.self, from: json(runtime)) == EURGBP("0.87"))
    }

    @Test("A typed rate and its runtime form write the same JSON")
    func encodingCommutesWithErasure() throws {
        let eurGbp = try #require(EURGBP("0.87"))
        let usdJpy = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>("149.5"))
        let ethGbp = try FX.ExchangeRateOf<Ether, Currencies.GBP>(string: "3200.12")

        #expect(try json(FX.ExchangeRate(eurGbp)) == json(eurGbp))
        #expect(try json(FX.ExchangeRate(usdJpy)) == json(usdJpy))
        #expect(try json(FX.ExchangeRate(ethGbp)) == json(ethGbp))
    }

    @Test("A shipped currency's scale, when written, is accepted if it is the currency's own")
    func acceptsAShippedCurrencysOwnScale() throws {
        let expected = try #require(FX.ExchangeRate("0.87", from: .eur, to: .gbp))
        let text = #"{"from":"EUR","fromScale":2,"to":"GBP","toScale":2,"rate":"0.87"}"#

        #expect(try decoded(FX.ExchangeRate.self, from: text) == expected)
        #expect(try decoded(EURGBP.self, from: text) == EURGBP("0.87"))
    }

    @Test("A code the ISO table doesn't ship, with no scale, is refused, naming the field")
    func refusesAnUnknownCodeWithoutAScale() throws {
        let context = try refusal(FX.ExchangeRate.self, from: #"{"from":"XYZ","to":"GBP","rate":"1"}"#)

        #expect(context?.codingPath.last?.stringValue == "from")
        #expect(context?.debugDescription.contains(#"Unknown currency code "XYZ" in the "from" field"#) == true)
        #expect(context?.debugDescription.contains(#""fromScale""#) == true)
    }

    @Test("Text that is not a currency code is refused, naming the field")
    func refusesTextThatIsNotACode() throws {
        let context = try refusal(FX.ExchangeRate.self, from: #"{"from":"EUR","to":"gb","rate":"1"}"#)

        #expect(context?.codingPath.last?.stringValue == "to")
        #expect(context?.debugDescription.contains(#""gb" in the "to" field"#) == true)
    }

    @Test(
        "A shipped code at another scale is refused, naming the scale field",
        arguments: [
            (#"{"from":"EUR","fromScale":3,"to":"GBP","rate":"0.87"}"#, "fromScale", "EUR", 3),
            (#"{"from":"EUR","to":"GBP","toScale":0,"rate":"0.87"}"#, "toScale", "GBP", 0),
        ]
    )
    func refusesAShippedCodeAtAnotherScale(_ text: String, field: String, code: String, scale: Int) throws {
        let context = try refusal(FX.ExchangeRate.self, from: text)

        #expect(context?.codingPath.last?.stringValue == field)
        #expect(context?.debugDescription.contains("Expected \(code) with a scale of 2 but read \(scale)") == true)
        #expect(context?.debugDescription.contains(#"in the "\#(field)" field"#) == true)
    }

    @Test("A scale outside 0 to 18 is refused, naming the scale field", arguments: [-1, 19])
    func refusesAScaleOutOfRange(_ scale: Int) throws {
        let context = try refusal(
            FX.ExchangeRate.self,
            from: #"{"from":"XYZ","fromScale":\#(scale),"to":"GBP","rate":"1"}"#
        )

        #expect(context?.codingPath.last?.stringValue == "fromScale")
        #expect(context?.debugDescription.contains("from 0 to 18") == true)
        #expect(context?.debugDescription.contains("read \(scale)") == true)
    }

    @Test("A typed rate refuses a code other than its own, naming the field")
    func typedRefusesAnotherCode() throws {
        let context = try refusal(EURGBP.self, from: #"{"from":"USD","fromScale":2,"to":"GBP","rate":"0.87"}"#)

        #expect(context?.codingPath.last?.stringValue == "from")
        #expect(context?.debugDescription.contains(#"Expected EUR but read "USD" in the "from" field"#) == true)
    }

    // An unknown key used to be ignored, so this read as €1 = £0.87 whatever the scale said.
    @Test("A typed rate refuses its own code at another scale")
    func typedRefusesItsCodeAtAnotherScale() throws {
        let context = try refusal(EURGBP.self, from: #"{"from":"EUR","fromScale":3,"to":"GBP","rate":"0.87"}"#)

        #expect(context?.codingPath.last?.stringValue == "fromScale")
        #expect(context?.debugDescription.contains("Expected EUR with a scale of 2 but read 3") == true)
    }

    @Test("A typed custom rate refuses its code at another scale")
    func typedCustomRefusesItsCodeAtAnotherScale() throws {
        let context = try refusal(
            FX.ExchangeRateOf<Ether, Currencies.GBP>.self,
            from: #"{"from":"ETH","fromScale":2,"to":"GBP","rate":"3200.12"}"#
        )

        #expect(context?.codingPath.last?.stringValue == "fromScale")
        #expect(context?.debugDescription.contains("Expected ETH with a scale of 18 but read 2") == true)
    }

    @Test("A quote finer than the pair holds is refused, naming the pair and the places it holds")
    func refusesAnInexactQuote() throws {
        let context = try refusal(
            FX.ExchangeRate.self,
            from: #"{"from":"ETH","fromScale":18,"to":"GBP","rate":"3200.125"}"#
        )

        #expect(context?.codingPath.last?.stringValue == "rate")
        #expect(context?.debugDescription.contains("A rate from ETH to GBP holds a quote to at most 2 decimal places") == true)
    }

    @Test(
        "A runtime rate missing a field, or with its quote as a number, is refused",
        arguments: [
            #"{"to":"GBP","rate":"0.87"}"#,
            #"{"from":"EUR","rate":"0.87"}"#,
            #"{"from":"EUR","to":"GBP"}"#,
            #"{"from":"EUR","to":"GBP","rate":0.87}"#,
            #"{"from":"EUR","fromScale":"2","to":"GBP","rate":"0.87"}"#,
        ]
    )
    func refusesAMissingOrMistypedField(_ text: String) {
        #expect(throws: DecodingError.self) {
            try decoded(FX.ExchangeRate.self, from: text)
        }
    }
}
