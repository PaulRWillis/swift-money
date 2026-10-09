import Foundation
import SwiftMoneyCore
import Testing

private typealias EURGBP = FX.ExchangeRate<Currencies.EUR, Currencies.GBP>

// Keys are sorted because `JSONEncoder` does not otherwise fix their order.
private func json<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()

    encoder.outputFormatting = .sortedKeys

    return String(decoding: try encoder.encode(value), as: UTF8.self)
}

private func decoded<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
    try JSONDecoder().decode(type, from: Data(text.utf8))
}

@Suite("Exchange Rate Codable Tests")
struct ExchangeRateCodableTests {

    @Test("A rate is written as its two currency codes and its market quote")
    func encodes() throws {
        let rate = try #require(EURGBP("0.87"))

        #expect(try json(rate) == #"{"from":"EUR","rate":"0.87","to":"GBP"}"#)
    }

    @Test("A rate between currencies of different scales is written per major unit")
    func encodesPerMajorUnit() throws {
        let rate = try #require(FX.ExchangeRate<Currencies.USD, Currencies.JPY>("149.5"))

        #expect(try json(rate) == #"{"from":"USD","rate":"149.5","to":"JPY"}"#)
    }

    @Test("A whole rate is written without a decimal point")
    func encodesAWholeRate() throws {
        let rate = try #require(EURGBP("2"))

        #expect(try json(rate) == #"{"from":"EUR","rate":"2","to":"GBP"}"#)
    }

    @Test("A rate reads back from what it writes")
    func decodes() throws {
        let rate = try #require(EURGBP("0.87"))

        #expect(try decoded(EURGBP.self, from: #"{"from":"EUR","to":"GBP","rate":"0.87"}"#) == rate)
    }

    // ¥1 = $0.0066889632107023411… needs more than eighteen places once quoted per major unit.
    @Test("A rate whose market quote needs more than eighteen places keeps every digit")
    func roundTripsBeyondEighteenPlaces() throws {
        let jpyUsd = try #require(FX.ExchangeRate<Currencies.USD, Currencies.JPY>("149.5")).inverted()
        let text = try json(jpyUsd)

        #expect(try decoded(FX.ExchangeRate<Currencies.JPY, Currencies.USD>.self, from: text) == jpyUsd)
    }

    @Test("A quote finer than a rate keeps is rounded to the nearest, ties to even")
    func decodingRounds() throws {
        let expected = try #require(EURGBP("0.000000000000000002"))
        let text = #"{"from":"EUR","to":"GBP","rate":"0.0000000000000000015"}"#

        #expect(try decoded(EURGBP.self, from: text) == expected)
    }

    @Test(
        "A rate for another pair of currencies is refused",
        arguments: [
            #"{"from":"USD","to":"GBP","rate":"0.87"}"#,
            #"{"from":"EUR","to":"USD","rate":"0.87"}"#,
            #"{"from":"GBP","to":"EUR","rate":"0.87"}"#,
        ]
    )
    func refusesAnotherPair(_ text: String) {
        #expect(throws: DecodingError.self) {
            try decoded(EURGBP.self, from: text)
        }
    }

    @Test(
        "A quote that is not a positive decimal is refused",
        arguments: ["0", "-0.87", "abc", "", "1/3", "5%", "1e3", "0.8.7"]
    )
    func refusesAQuoteThatIsNotAPositiveDecimal(_ quote: String) {
        let text = #"{"from":"EUR","to":"GBP","rate":"\#(quote)"}"#

        #expect(throws: DecodingError.self) {
            try decoded(EURGBP.self, from: text)
        }
    }

    @Test(
        "A quote too large to hold, or so small it rounds to zero, is refused",
        arguments: ["1000000000000000000000", "0.0000000000000000004"]
    )
    func refusesAQuoteOutOfRange(_ quote: String) {
        let text = #"{"from":"EUR","to":"GBP","rate":"\#(quote)"}"#

        #expect(throws: DecodingError.self) {
            try decoded(EURGBP.self, from: text)
        }
    }

    @Test(
        "A rate missing a field, or with its quote as a number, is refused",
        arguments: [
            #"{"to":"GBP","rate":"0.87"}"#,
            #"{"from":"EUR","rate":"0.87"}"#,
            #"{"from":"EUR","to":"GBP"}"#,
            #"{"from":"EUR","to":"GBP","rate":0.87}"#,
        ]
    )
    func refusesAMissingOrMistypedField(_ text: String) {
        #expect(throws: DecodingError.self) {
            try decoded(EURGBP.self, from: text)
        }
    }
}
