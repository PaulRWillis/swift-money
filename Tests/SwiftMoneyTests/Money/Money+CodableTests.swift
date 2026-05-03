import Foundation
import SwiftMoney
import Testing

// MARK: - Helper

private func json(_ value: some Encodable) throws -> String {
    try #require(String(data: JSONEncoder().encode(value), encoding: .utf8))
}

private func json(_ encoder: JSONEncoder, _ value: some Encodable) throws -> String {
    try #require(String(data: encoder.encode(value), encoding: .utf8))
}

/// Encodes `value` with `.sortedKeys` for deterministic key ordering in exact-match assertions.
private func jsonSorted(_ encoder: JSONEncoder, _ value: some Encodable) throws -> String {
    let e = encoder
    e.outputFormatting = .sortedKeys
    return try #require(String(data: e.encode(value), encoding: .utf8))
}

// MARK: - Default strategy

@Suite("Money - Codable: default strategy")
struct Money_Codable_DefaultStrategyTests {

    @Test("Default strategy produces object JSON shape")
    func defaultIsObject() throws {
        let money = Money<GBP>(minorUnits: 125)
        let output = try json(money)
        #expect(output.contains("\"currencyCode\""))
        #expect(output.contains("\"GBP\""))
        #expect(output.contains("\"amount\""))
        #expect(output.contains("1.25"))
    }

    @Test("Default strategy round-trips correctly")
    func defaultRoundTrip() throws {
        let original = Money<GBP>(minorUnits: 125)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Money<GBP>.self, from: data)
        #expect(decoded == original)
    }

    @Test("JSONEncoder.moneyEncodingStrategy property returns .object when unset")
    func encoderDefaultProperty() {
        let encoder = JSONEncoder()
        // Can't compare enums directly without Equatable, but we can verify the
        // property accessor doesn't crash and the output is the object shape.
        let money = Money<GBP>(minorUnits: 100)
        #expect(throws: Never.self) { _ = try json(encoder, money) }
    }

    @Test("JSONDecoder.moneyDecodingStrategy property returns .object when unset")
    func decoderDefaultProperty() throws {
        let decoder = JSONDecoder()
        let data = try JSONEncoder().encode(Money<GBP>(minorUnits: 100))
        #expect(throws: Never.self) { _ = try decoder.decode(Money<GBP>.self, from: data) }
    }
}

// MARK: - .object strategy

@Suite("Money - Codable: .object strategy")
struct Money_Codable_ObjectStrategyTests {

    // MARK: .object(amount: .majorUnits)

    @Test("object(majorUnits): GBP encodes to expected JSON")
    func objectMajorUnitsGBPEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
        let output = try jsonSorted(encoder, Money<GBP>(minorUnits: 125))
        #expect(output == #"{"amount":1.25,"currencyCode":"GBP"}"#)
    }

    @Test("object(majorUnits): JPY encodes to expected JSON (minQ = 1)")
    func objectMajorUnitsJPYEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
        let output = try jsonSorted(encoder, Money<JPY>(minorUnits: 1000))
        #expect(output == #"{"amount":1000,"currencyCode":"JPY"}"#)
    }

    @Test("object(majorUnits): KWD encodes 3-decimal-place amount")
    func objectMajorUnitsKWDEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
        let output = try jsonSorted(encoder, Money<TestKWD>(minorUnits: 1055))
        #expect(output == #"{"amount":1.055,"currencyCode":"KWD"}"#)
    }

    @Test("object(majorUnits): GBP round-trips correctly")
    func objectMajorUnitsGBPRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(amount: .majorUnits)
        let original = Money<GBP>(minorUnits: 12_345)
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("object(majorUnits): negative value round-trips correctly")
    func objectMajorUnitsNegativeRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(amount: .majorUnits)
        let original = Money<GBP>(minorUnits: -9_876)
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("object(majorUnits): zero round-trips correctly")
    func objectMajorUnitsZeroRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(amount: .majorUnits)
        let original = Money<GBP>.zero
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("object(majorUnits): KWD round-trips correctly (minQ = 1000)")
    func objectMajorUnitsKWDRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(amount: .majorUnits)
        let original = Money<TestKWD>(minorUnits: 1055)
        let decoded = try decoder.decode(Money<TestKWD>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    // MARK: .object(amount: .minorUnits)

    @Test("object(minorUnits): GBP encodes to expected JSON")
    func objectMinorUnitsGBPEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .minorUnits)
        let output = try jsonSorted(encoder, Money<GBP>(minorUnits: 125))
        #expect(output == #"{"amount":125,"currencyCode":"GBP"}"#)
    }

    @Test("object(minorUnits): GBP round-trips correctly")
    func objectMinorUnitsGBPRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .minorUnits)
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(amount: .minorUnits)
        let original = Money<GBP>(minorUnits: 12_345)
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    // MARK: .object(amount: .string)

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

    @Test("object: NaN encoding throws EncodingError")
    func objectNaNThrows() {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
        #expect(throws: EncodingError.self) {
            try encoder.encode(Money<GBP>.nan)
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

// MARK: - .minorUnits strategy

@Suite("Money - Codable: .minorUnits strategy")
struct Money_Codable_MinorUnitsStrategyTests {

    @Test("minorUnits: GBP encodes to bare integer")
    func minorUnitsEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        let output = try json(encoder, Money<GBP>(minorUnits: 125))
        #expect(output == "125")
    }

    @Test("minorUnits: negative value encodes correctly")
    func minorUnitsNegativeEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        let output = try json(encoder, Money<GBP>(minorUnits: -9_876))
        #expect(output == "-9876")
    }

    @Test("minorUnits: zero encodes as 0")
    func minorUnitsZeroEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        let output = try json(encoder, Money<GBP>.zero)
        #expect(output == "0")
    }

    @Test("minorUnits: GBP round-trips correctly")
    func minorUnitsRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .minorUnits
        let original = Money<GBP>(minorUnits: 12_345)
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("minorUnits: JPY round-trips correctly (minQ = 1)")
    func minorUnitsJPYRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .minorUnits
        let original = Money<JPY>(minorUnits: 99_999)
        let decoded = try decoder.decode(Money<JPY>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("minorUnits: NaN encodes and decodes correctly (sentinel preserved)")
    func minorUnitsNaNRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .minorUnits
        let nan = Money<GBP>.nan
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(nan))
        #expect(decoded.isNaN)
    }

    @Test("minorUnits: decoding known JSON value")
    func minorUnitsDecoding() throws {
        let json = try #require("125".data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .minorUnits
        let decoded = try decoder.decode(Money<GBP>.self, from: json)
        #expect(decoded.minorUnits == 125)
    }
}

// MARK: - .majorUnits strategy

@Suite("Money - Codable: .majorUnits strategy")
struct Money_Codable_MajorUnitsStrategyTests {

    @Test("majorUnits: GBP encodes to decimal JSON number")
    func majorUnitsEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        let output = try json(encoder, Money<GBP>(minorUnits: 125))
        #expect(output == "1.25")
    }

    @Test("majorUnits: JPY encodes to integer JSON number (minQ = 1)")
    func majorUnitsJPYEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        let output = try json(encoder, Money<JPY>(minorUnits: 1000))
        #expect(output == "1000")
    }

    @Test("majorUnits: KWD encodes to 3-decimal JSON number")
    func majorUnitsKWDEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        let output = try json(encoder, Money<TestKWD>(minorUnits: 1055))
        #expect(output == "1.055")
    }

    @Test("majorUnits: smallest GBP value (1p) encodes correctly")
    func majorUnitsOnePenny() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        let output = try json(encoder, Money<GBP>(minorUnits: 1))
        #expect(output == "0.01")
    }

    @Test("majorUnits: negative GBP value encodes correctly")
    func majorUnitsNegativeEncoding() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        let output = try json(encoder, Money<GBP>(minorUnits: -125))
        #expect(output == "-1.25")
    }

    @Test("majorUnits: GBP round-trips correctly")
    func majorUnitsRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .majorUnits
        let original = Money<GBP>(minorUnits: 12_345)
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("majorUnits: JPY round-trips correctly (minQ = 1)")
    func majorUnitsJPYRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .majorUnits
        let original = Money<JPY>(minorUnits: 99_999)
        let decoded = try decoder.decode(Money<JPY>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("majorUnits: KWD round-trips correctly (minQ = 1000)")
    func majorUnitsKWDRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .majorUnits
        let original = Money<TestKWD>(minorUnits: 1055)
        let decoded = try decoder.decode(Money<TestKWD>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("majorUnits: zero round-trips correctly")
    func majorUnitsZeroRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .majorUnits
        let original = Money<GBP>.zero
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("majorUnits: NaN encoding throws EncodingError")
    func majorUnitsNaNThrows() {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .majorUnits
        #expect(throws: EncodingError.self) {
            try encoder.encode(Money<GBP>.nan)
        }
    }

    @Test("majorUnits: decoding known JSON value")
    func majorUnitsDecoding() throws {
        let json = try #require("1.25".data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .majorUnits
        let decoded = try decoder.decode(Money<GBP>.self, from: json)
        #expect(decoded.minorUnits == 125)
    }

    /// Validates the rounding-based mitigation for the historical SR-7054
    /// Double-intermediate precision issue.
    ///
    /// Even if a JSON parser were to pass `1.2999999...` instead of `1.30`, the
    /// `.plain` rounding to 0 decimal places *after* multiplying by minQ (100)
    /// would yield 130 minor units — the correct result.
    @Test("majorUnits: rounding absorbs sub-minor-unit imprecision")
    func majorUnitsRoundingMitigation() throws {
        // Manually construct a Decimal that approximates 1.30 with a tiny error,
        // as a Double-intermediate parser might produce.
        // 1.30 * 100 = 130. Even 1.299999999 * 100 = 129.9999... rounds to 130.
        let imprecise = Decimal(string: "1.299999999")!  // simulated Double artefact
        var product = imprecise * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &product, 0, .plain)
        #expect(rounded == 130)
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

    @Test("string: NaN encoding throws EncodingError")
    func stringNaNThrows() {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .string(locale: enGB)
        #expect(throws: EncodingError.self) {
            try encoder.encode(Money<GBP>.nan)
        }
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

// MARK: - JSONEncoder / JSONDecoder property API

@Suite("Money - Codable: encoder/decoder properties")
struct Money_Codable_PropertyAPITests {

    @Test("moneyEncodingStrategy setter is respected")
    func encoderPropertyRespected() throws {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        let output = try json(encoder, Money<GBP>(minorUnits: 42))
        #expect(output == "42")
    }

    @Test("moneyDecodingStrategy setter is respected")
    func decoderPropertyRespected() throws {
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .minorUnits
        let json = try #require("42".data(using: .utf8))
        let decoded = try decoder.decode(Money<GBP>.self, from: json)
        #expect(decoded.minorUnits == 42)
    }

    @Test("userInfo key can be set directly (CodingUserInfoKey API)")
    func userInfoKeyDirect() throws {
        let encoder = JSONEncoder()
        encoder.userInfo[.moneyEncodingStrategy] = MoneyEncodingStrategy.minorUnits
        let output = try json(encoder, Money<GBP>(minorUnits: 99))
        #expect(output == "99")
    }
}
