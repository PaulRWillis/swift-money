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

// MARK: - .object strategy

@Suite("AnyMoney – Codable – .object strategy")
struct AnyMoney_CodableTests_ObjectStrategy {

    private let resolver: @Sendable (CurrencyCode) -> MinimalQuantisation? = { code in
        switch code.stringValue {
        case "TST_100": return 100
        case "TST_1": return 1
        case "GBP": return 100
        default: return nil
        }
    }

    private func makeSortedEncoder(strategy: AnyMoneyEncodingStrategy) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.anyMoneyEncodingStrategy = strategy
        return encoder
    }

    private func roundTrip(
        _ value: AnyMoney,
        encoding: AnyMoneyEncodingStrategy,
        decoding: AnyMoneyDecodingStrategy
    ) throws -> AnyMoney {
        let encoder = JSONEncoder()
        encoder.anyMoneyEncodingStrategy = encoding
        let decoder = JSONDecoder()
        decoder.anyMoneyDecodingStrategy = decoding
        return try decoder.decode(AnyMoney.self, from: encoder.encode(value))
    }

    // MARK: Encoding shape

    @Test(".object(majorUnits): JSON has currencyCode and amount, not minimalQuantisation")
    func objectMajorUnitsEncodingShape() throws {
        let any = Money<TST_100>(minorUnits: 500).erased
        let data = try makeSortedEncoder(strategy: .object(amount: .majorUnits)).encode(any)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"currencyCode\""))
        #expect(json.contains("\"amount\""))
        #expect(!json.contains("\"minimalQuantisation\""))
        #expect(!json.contains("\"minorUnits\""))
    }

    @Test(".object(minorUnits): JSON amount is the raw minor-unit integer")
    func objectMinorUnitsEncodingShape() throws {
        let any = Money<TST_100>(minorUnits: 500).erased
        let data = try makeSortedEncoder(strategy: .object(amount: .minorUnits)).encode(any)
        let json = try #require(String(data: data, encoding: .utf8))
        // sortedKeys: "amount" < "currencyCode"
        #expect(json == #"{"amount":500,"currencyCode":"TST_100"}"#)
    }

    @Test(".object static shorthand is equivalent to .object(amount: .majorUnits)")
    func objectStaticShorthand() throws {
        let any = Money<TST_100>(minorUnits: 500).erased
        let j1 = try #require(String(data: makeSortedEncoder(strategy: .object).encode(any), encoding: .utf8))
        let j2 = try #require(String(data: makeSortedEncoder(strategy: .object(amount: .majorUnits)).encode(any), encoding: .utf8))
        #expect(j1 == j2)
    }

    // MARK: Round-trips

    @Test(".object(majorUnits): TST_100 round-trips correctly")
    func objectMajorUnitsTST100RoundTrip() throws {
        let original = Money<TST_100>(minorUnits: 750).erased
        let decoded = try roundTrip(original,
            encoding: .object(amount: .majorUnits),
            decoding: .object(amount: .majorUnits, resolver: resolver))
        #expect(decoded == original)
    }

    @Test(".object(majorUnits): TST_1 (ratio-1) round-trips correctly")
    func objectMajorUnitsTST1RoundTrip() throws {
        let original = Money<TST_1>(minorUnits: 1000).erased
        let decoded = try roundTrip(original,
            encoding: .object(amount: .majorUnits),
            decoding: .object(amount: .majorUnits, resolver: resolver))
        #expect(decoded == original)
    }

    @Test(".object(majorUnits): negative amount round-trips correctly")
    func objectMajorUnitsNegativeRoundTrip() throws {
        let original = Money<TST_100>(minorUnits: -250).erased
        let decoded = try roundTrip(original,
            encoding: .object(amount: .majorUnits),
            decoding: .object(amount: .majorUnits, resolver: resolver))
        #expect(decoded == original)
    }

    @Test(".object(minorUnits): TST_100 round-trips correctly")
    func objectMinorUnitsTST100RoundTrip() throws {
        let original = Money<TST_100>(minorUnits: 999).erased
        let decoded = try roundTrip(original,
            encoding: .object(amount: .minorUnits),
            decoding: .object(amount: .minorUnits, resolver: resolver))
        #expect(decoded == original)
    }

    @Test(".object(minorUnits): NaN is preserved")
    func objectMinorUnitsNaNPreserved() throws {
        let original = Money<TST_100>.nan.erased
        let decoded = try roundTrip(original,
            encoding: .object(amount: .minorUnits),
            decoding: .object(amount: .minorUnits, resolver: resolver))
        #expect(decoded.isNaN)
        #expect(decoded.currencyCode == TST_100.code)
    }

    @Test(".object(string): GBP round-trips correctly")
    func objectStringGBPRoundTrip() throws {
        let locale = Locale(identifier: "en_GB")
        let original = Money<GBP>(minorUnits: 12_345).erased
        let decoded = try roundTrip(original,
            encoding: .object(amount: .string(locale: locale)),
            decoding: .object(amount: .string(locale: locale), resolver: resolver))
        #expect(decoded == original)
    }

    // MARK: NaN error handling

    @Test(".object(majorUnits): encoding NaN throws EncodingError")
    func objectMajorUnitsNaNThrows() throws {
        let nan = Money<TST_100>.nan.erased
        #expect(throws: EncodingError.self) {
            try makeSortedEncoder(strategy: .object(amount: .majorUnits)).encode(nan)
        }
    }

    @Test(".object(string): encoding NaN throws EncodingError")
    func objectStringNaNThrows() throws {
        let nan = Money<TST_100>.nan.erased
        #expect(throws: EncodingError.self) {
            try makeSortedEncoder(strategy: .object(amount: .string(locale: .current))).encode(nan)
        }
    }

    // MARK: Resolver errors

    @Test(".object: resolver returning nil throws DecodingError")
    func objectResolverNilThrows() throws {
        let json = #"{"currencyCode":"UNKNOWN","amount":5.0}"#
        let data = try #require(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.anyMoneyDecodingStrategy = .object(amount: .majorUnits, resolver: { _ in nil })
        #expect(throws: DecodingError.self) {
            try decoder.decode(AnyMoney.self, from: data)
        }
    }
}

// MARK: - Strategy property API

@Suite("AnyMoney – Codable – Strategy property API")
struct AnyMoney_CodableTests_StrategyAPI {

    @Test("JSONEncoder.anyMoneyEncodingStrategy defaults to .full")
    func encoderDefaultStrategyIsFull() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(Money<TST_100>(minorUnits: 500).erased)
        let json = try #require(String(data: data, encoding: .utf8))
        // .full includes minimalQuantisation; .object does not
        #expect(json.contains("minimalQuantisation"))
    }

    @Test("JSONEncoder.anyMoneyEncodingStrategy setter is respected")
    func encoderStrategySetterRespected() throws {
        let encoder = JSONEncoder()
        encoder.anyMoneyEncodingStrategy = .object(amount: .minorUnits)
        let data = try encoder.encode(Money<TST_100>(minorUnits: 500).erased)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(!json.contains("minimalQuantisation"))
        #expect(json.contains("amount"))
    }

    @Test("JSONDecoder.anyMoneyDecodingStrategy defaults to .full")
    func decoderDefaultStrategyIsFull() throws {
        let fullJSON = #"{"minorUnits":500,"currencyCode":"TST_100","minimalQuantisation":100}"#
        let data = try #require(fullJSON.data(using: .utf8))
        let any = try JSONDecoder().decode(AnyMoney.self, from: data)
        #expect(any.minorUnits == 500)
        #expect(any.currencyCode.stringValue == "TST_100")
    }

    @Test("JSONDecoder.anyMoneyDecodingStrategy setter is respected")
    func decoderStrategySetterRespected() throws {
        let objectJSON = #"{"currencyCode":"TST_100","amount":500}"#
        let data = try #require(objectJSON.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.anyMoneyDecodingStrategy = .object(amount: .minorUnits, resolver: { _ in MinimalQuantisation(100) })
        let any = try decoder.decode(AnyMoney.self, from: data)
        #expect(any.minorUnits == 500)
        #expect(any.currencyCode.stringValue == "TST_100")
    }
}
