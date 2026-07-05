import Foundation
import SwiftMoney
import SwiftMoneySerialization
import Testing

@Suite("Money - Codable: .object(.majorUnits) strategy")
struct Money_Codable_Object_MajorUnits_StrategyTests {

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.moneyEncodingStrategy = .object(.majorUnits)
        return e
    }

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.moneyDecodingStrategy = .object(.majorUnits)
        return d
    }

    @Test("object(majorUnits): GBP encodes to expected JSON")
    func objectMajorUnitsGBPEncoding() throws {
        encoder.moneyEncodingStrategy = .object(.majorUnits)
        let output = try jsonSorted(encoder, Money<GBP>(minorUnits: 125))
        #expect(output == #"{"amount":1.25,"currencyCode":"GBP"}"#)
    }

    @Test("object(majorUnits): JPY encodes to expected JSON (minQ = 1)")
    func objectMajorUnitsJPYEncoding() throws {
        let output = try jsonSorted(encoder, Money<JPY>(minorUnits: 1000))
        #expect(output == #"{"amount":1000,"currencyCode":"JPY"}"#)
    }

    @Test("object(majorUnits): KWD encodes 3-decimal-place amount")
    func objectMajorUnitsKWDEncoding() throws {
        let output = try jsonSorted(encoder, Money<TestKWD>(minorUnits: 1055))
        #expect(output == #"{"amount":1.055,"currencyCode":"KWD"}"#)
    }

    @Test("object(majorUnits): GBP round-trips correctly")
    func objectMajorUnitsGBPRoundTrip() throws {
        let original = Money<GBP>(minorUnits: 12_345)
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("object(majorUnits): negative value round-trips correctly")
    func objectMajorUnitsNegativeRoundTrip() throws {
        let original = Money<GBP>(minorUnits: -9_876)
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("object(majorUnits): zero round-trips correctly")
    func objectMajorUnitsZeroRoundTrip() throws {
        let original = Money<GBP>.zero
        let decoded = try decoder.decode(Money<GBP>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }

    @Test("object(majorUnits): KWD round-trips correctly (minQ = 1000)")
    func objectMajorUnitsKWDRoundTrip() throws {
        let original = Money<TestKWD>(minorUnits: 1055)
        let decoded = try decoder.decode(Money<TestKWD>.self, from: encoder.encode(original))
        #expect(decoded == original)
    }
}
