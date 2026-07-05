import Foundation
import SwiftMoney
import SwiftMoneySerialization
import Testing

@Suite("Money - Codable: default strategy")
struct Money_Codable_DefaultStrategyTests {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Test("Default strategy produces object JSON shape")
    func defaultIsObject() throws {
        let output = try jsonSorted(encoder, Money<GBP>(minorUnits: 125))
        #expect(output == #"{"amount":1.25,"currencyCode":"GBP"}"#)
    }

    @Test("Default strategy round-trips correctly")
    func defaultRoundTrip() throws {
        let original = Money<GBP>(minorUnits: 125)
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Money<GBP>.self, from: data)
        #expect(decoded == original)
    }

    @Test("Money<GBP> encodes and decodes correctly (positive)")
    func codableRoundTripPositive() throws {
        let original = Money<GBP>(minorUnits: 12_345)
        let data     = try encoder.encode(original)
        let decoded  = try decoder.decode(Money<GBP>.self, from: data)
        #expect(decoded == original)
    }

    @Test("Money<GBP> encodes and decodes correctly (negative)")
    func codableRoundTripNegative() throws {
        let original = Money<GBP>(minorUnits: -9_876)
        let data     = try encoder.encode(original)
        let decoded  = try decoder.decode(Money<GBP>.self, from: data)
        #expect(decoded == original)
    }

    @Test("Money<GBP> encodes and decodes correctly (zero)")
    func codableRoundTripZero() throws {
        let original = Money<GBP>.zero
        let data     = try encoder.encode(original)
        let decoded  = try decoder.decode(Money<GBP>.self, from: data)
        #expect(decoded == original)
    }

    @Test("Money<JPY> encodes and decodes correctly (minQ = 1)")
    func codableJPY() throws {
        let original = Money<JPY>(minorUnits: 99_999)
        let data     = try encoder.encode(original)
        let decoded  = try decoder.decode(Money<JPY>.self, from: data)
        #expect(decoded == original)
    }
}
