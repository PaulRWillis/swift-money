import Foundation
import Testing
import SwiftMoney
import XCTest

@Suite("AnyMoney – Codable")
struct AnyMoney_CodableTests {

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Helpers

    /// A bare struct that matches the expected JSON shape, used to inspect
    /// the encoded output without relying on AnyMoney's own decode path.
    private struct RawDecoded: Decodable {
        let minorUnits: Int64
        let currencyCode: String
        let minimalQuantisation: Int64
    }

    private func encodeAndDecodeRaw(_ value: AnyMoney) throws -> RawDecoded {
        let data = try encoder.encode(value)
        return try decoder.decode(RawDecoded.self, from: data)
    }

    private func roundTrip(_ value: AnyMoney) throws -> AnyMoney {
        let data = try encoder.encode(value)
        return try decoder.decode(AnyMoney.self, from: data)
    }

    // MARK: - Encoding shape

    @Test("Encoded JSON contains correct minorUnits")
    func encodedMinorUnits() throws {
        let any = Money<TST_100>(minorUnits: 500).erased
        let raw = try encodeAndDecodeRaw(any)
        #expect(raw.minorUnits == 500)
    }

    @Test("Encoded JSON contains correct currencyCode")
    func encodedCurrencyCode() throws {
        let any = Money<TST_100>(minorUnits: 500).erased
        let raw = try encodeAndDecodeRaw(any)
        #expect(raw.currencyCode == TST_100.code.stringValue)
    }

    @Test("Encoded JSON contains correct minimalQuantisation")
    func encodedMinimalQuantisation() throws {
        let any = Money<TST_100>(minorUnits: 500).erased
        let raw = try encodeAndDecodeRaw(any)
        #expect(raw.minimalQuantisation == 100)
    }

    @Test("Encoded JSON contains correct minimalQuantisation for ratio-1 currency")
    func encodedMinimalQuantisationRatio1() throws {
        let any = Money<TST_1>(minorUnits: 500).erased
        let raw = try encodeAndDecodeRaw(any)
        #expect(raw.minimalQuantisation == 1)
    }

    // MARK: - Round-trip scalar preservation

    @Test("Round-trip preserves minorUnits")
    func roundTripMinorUnits() throws {
        let original = Money<TST_100>(minorUnits: 9876).erased
        let decoded = try roundTrip(original)
        #expect(decoded.minorUnits == original.minorUnits)
    }

    @Test("Round-trip preserves currencyCode")
    func roundTripCurrencyCode() throws {
        let original = Money<TST_100>(minorUnits: 9876).erased
        let decoded = try roundTrip(original)
        #expect(decoded.currencyCode == original.currencyCode)
    }

    @Test("Round-trip preserves minimalQuantisation")
    func roundTripMinimalQuantisation() throws {
        let original = Money<TST_100>(minorUnits: 9876).erased
        let decoded = try roundTrip(original)
        #expect(decoded.minimalQuantisation == original.minimalQuantisation)
    }

    @Test("Round-trip decoded value equals original (Equatable)")
    func roundTripEquals() throws {
        let original = Money<TST_100>(minorUnits: 9876).erased
        let decoded = try roundTrip(original)
        #expect(decoded == original)
    }

    // MARK: - currency is nil after decode

    @Test("currency metatype is nil after decode")
    func currencyNilAfterDecode() throws {
        let original = Money<TST_100>(minorUnits: 500).erased
        let decoded = try roundTrip(original)
        // XCTAssertNil needed because apparently macOS 15+ introduced
        // some ABI change that causes a crash here using `#expect`. Yay
        XCTAssertNil(decoded.currency)
    }

    // MARK: - Derived values still work after decode

    @Test("decimalValue is preserved after round-trip")
    func decimalValueAfterRoundTrip() throws {
        let original = Money<TST_100>(minorUnits: 150).erased
        let decoded = try roundTrip(original)
        #expect(decoded.decimalValue == original.decimalValue)
    }

    @Test("formatted() is preserved after round-trip")
    func formattedAfterRoundTrip() throws {
        let original = Money<GBP>(minorUnits: 150).erased
        let decoded = try roundTrip(original)
        #expect(decoded.formatted() == original.formatted())
    }

    // MARK: - NaN

    @Test("NaN encodes and decodes correctly")
    func nanRoundTrip() throws {
        let original = Money<TST_100>.nan.erased
        let decoded = try roundTrip(original)
        #expect(decoded.isNaN)
    }

    @Test("NaN round-trip preserves currencyCode")
    func nanRoundTripCurrencyCode() throws {
        let original = Money<TST_100>.nan.erased
        let decoded = try roundTrip(original)
        #expect(decoded.currencyCode == TST_100.code)
    }

    // MARK: - Ratio-1 currency

    @Test("Round-trip preserves ratio-1 currency")
    func roundTripRatio1() throws {
        let original = Money<TST_1>(minorUnits: 500).erased
        let decoded = try roundTrip(original)
        #expect(decoded == original)
        #expect(decoded.minimalQuantisation.int64Value == 1)
    }

    // MARK: - asMoney still works after decode

    @Test("asMoney returns typed value after round-trip for matching currency")
    func asMoneyAfterRoundTrip() throws {
        let original = Money<TST_100>(minorUnits: 500).erased
        let decoded = try roundTrip(original)
        let typed = try #require(decoded.asMoney(TST_100.self))
        #expect(typed == Money<TST_100>(minorUnits: 500))
    }

    @Test("asMoney returns nil after round-trip for mismatched currency")
    func asMoneyCurrencyMismatchAfterRoundTrip() throws {
        let original = Money<TST_100>(minorUnits: 500).erased
        let decoded = try roundTrip(original)
        #expect(decoded.asMoney(TST_1.self) == nil)
    }
}
