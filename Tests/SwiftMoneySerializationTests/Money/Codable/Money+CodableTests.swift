import Foundation
import SwiftMoney
import SwiftMoneySerialization
import Testing

/// A test currency backed by the real ISO 4217 code "KWD"
/// (Kuwaiti Dinar), which has 1000 fils to the dinar.
///
/// Used in localisation tests to exercise 3-decimal-place currencies.
/// Using the real ISO code ensures Foundation's formatter renders a
/// recognisable symbol and the fidelity comparison is meaningful.
enum TestKWD: Currency {
    static let code: CurrencyCode = "KWD"
    static let minimalQuantisation: MinimalQuantisation = 1000
}

@Suite("Money - Codable: .object(.minorUnits) strategy")
struct Money_Codable_Object_String_StrategyTests {

    @Test("object(string): GBP encodes amount as formatted string")
    func objectStringGBPEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .string(locale: Locale(identifier: "en_GB")))
        let output = try json(encoder, Money<GBP>(minorUnits: 150))
        #expect(output.contains("\"currencyCode\""))
        #expect(output.contains("\"GBP\""))
        #expect(output.contains("£1.50"))
    }

    @Test("object(string): GBP round-trips correctly")
    func objectStringGBPRoundTrip() throws {
        let locale = Locale(identifier: "en_GB")
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .string(locale: locale))
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(amount: .string(locale: locale))
        let original = Money<GBP>(minorUnits: 12_345)
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    // MARK: Currency mismatch

    @Test("object: currency mismatch throws DecodingError")
    func objectCurrencyMismatch() throws {
        let json = try #require(#"{"currencyCode":"USD","amount":1.25}"#.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(amount: .majorUnits)
        #expect(throws: DecodingError.self) {
            try decoder.decode(Money<GBP>.self, from: json)
        }
    }

    @Test("object: decoding from JSON with known values is correct")
    func objectDecoding() throws {
        let json = try #require(#"{"currencyCode":"GBP","amount":1.25}"#.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(amount: .majorUnits)
        let decoded = try decoder.decode(Money<GBP>.self, from: json)
        #expect(decoded.minorUnits == 125)
    }
}

// MARK: - .string strategy

@Suite("Money - Codable: .string strategy")
struct Money_Codable_StringStrategyTests {

    private let enGB = Locale(identifier: "en_GB")
    private let enUS = Locale(identifier: "en_US")

    @Test("string: GBP encodes to formatted string")
    func stringEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .string(locale: enGB)
        let output = try json(encoder, Money<GBP>(minorUnits: 150))
        #expect(output == "\"£1.50\"")
    }

    @Test("string: GBP round-trips correctly")
    func stringRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .string(locale: enGB)
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .string(locale: enGB)
        let original = Money<GBP>(minorUnits: 12_345)
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("string: JPY round-trips correctly (minQ = 1)")
    func stringJPYRoundTrip() throws {
        let locale = Locale(identifier: "ja_JP")
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .string(locale: locale)
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .string(locale: locale)
        let original = Money<JPY>(minorUnits: 1000)
        let decoded = try decoder.decode(Money<JPY>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("string: decoding invalid string throws DecodingError")
    func stringInvalidThrows() throws {
        let json = try #require("\"not-a-currency\"".data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .string(locale: enGB)
        #expect(throws: DecodingError.self) {
            try decoder.decode(Money<GBP>.self, from: json)
        }
    }
}
