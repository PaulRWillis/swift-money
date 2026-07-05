import Foundation
import SwiftMoney
import SwiftMoneySerialization
import Testing

@Suite("Money - Codable: .object(.minorUnits) strategy")
struct Money_Codable_Object_MinorUnits_StrategyTests {

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.moneyEncodingStrategy = .object(amount: .majorUnits)
        return e
    }

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.moneyDecodingStrategy = .object(amount: .majorUnits)
        return d
    }

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
}
