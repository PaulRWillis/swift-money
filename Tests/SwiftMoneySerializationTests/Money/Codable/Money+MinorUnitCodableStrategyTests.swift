import Foundation
import SwiftMoney
import SwiftMoneySerialization
import Testing

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

    @Test("minorUnits: decoding known JSON value")
    func minorUnitsDecoding() throws {
        let json = try #require("125".data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .minorUnits
        let decoded = try decoder.decode(Money<GBP>.self, from: json)
        #expect(decoded.minorUnits == 125)
    }
}

