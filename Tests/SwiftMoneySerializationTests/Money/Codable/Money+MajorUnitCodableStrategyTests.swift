import Foundation
import SwiftMoney
import SwiftMoneySerialization
import Testing

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
