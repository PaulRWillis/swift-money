import Testing
import Foundation
import SwiftMoney

@Suite("MoneyBag – Codable")
struct MoneyBag_CodableTests {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()
    private let decoder = JSONDecoder()

    // MARK: - Round-trip

    @Test("Empty bag round-trips through JSON")
    func emptyBagRoundTrips() throws {
        let original = MoneyBag()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MoneyBag.self, from: data)
        #expect(decoded == original)
        #expect(decoded.isEmpty)
    }

    @Test("Single-currency bag round-trips through JSON")
    func singleCurrencyRoundTrips() throws {
        let original = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MoneyBag.self, from: data)
        #expect(decoded == original)
    }

    @Test("Multi-currency bag round-trips through JSON")
    func multiCurrencyRoundTrips() throws {
        let original = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 900))
            .adding(Money<TST_100_000_000>(minorUnits: 1))
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MoneyBag.self, from: data)
        #expect(decoded == original)
    }

    @Test("Negative-amount entry round-trips through JSON")
    func negativeAmountRoundTrips() throws {
        let original = MoneyBag().subtracting(Money<TST_100>(minorUnits: 200))
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MoneyBag.self, from: data)
        #expect(decoded == original)
    }

    @Test("Zero-amount entry round-trips through JSON")
    func zeroAmountRoundTrips() throws {
        let original = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .subtracting(Money<TST_100>(minorUnits: 500))
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MoneyBag.self, from: data)
        #expect(decoded == original)
        #expect(!decoded.isEmpty) // zero entry preserved
    }

    // MARK: - Encoded shape

    @Test("Empty bag encodes to expected JSON shape")
    func emptyBagEncodesCorrectly() throws {
        let data = try encoder.encode(MoneyBag())
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json == #"{"entries":[]}"#)
    }

    @Test("Single-currency bag encodes to expected JSON shape")
    func singleCurrencyEncodesCorrectly() throws {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let data = try encoder.encode(bag)
        let json = try #require(String(data: data, encoding: .utf8))
        // entries array has one element with three scalar keys
        #expect(json.contains("\"entries\""))
        #expect(json.contains("\"currencyCode\""))
        #expect(json.contains("\"minimalQuantisation\""))
        #expect(json.contains("\"minorUnits\""))
        #expect(json.contains("500"))
        #expect(json.contains(TST_100.code.stringValue))
    }

    // MARK: - Decoded queries

    @Test("amount(in:) works correctly after decoding")
    func amountWorksAfterDecoding() throws {
        let original = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 700))
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MoneyBag.self, from: data)

        let tst100 = try #require(decoded.amount(in: TST_100.self))
        let tst1 = try #require(decoded.amount(in: TST_1.self))
        #expect(tst100 == Money<TST_100>(minorUnits: 300))
        #expect(tst1 == Money<TST_1>(minorUnits: 700))
    }

    @Test("contains(_:) works correctly after decoding")
    func containsWorksAfterDecoding() throws {
        let original = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MoneyBag.self, from: data)
        #expect(decoded.contains(TST_100.self))
        #expect(!decoded.contains(TST_1.self))
    }

    @Test("Decoded bag can be further mutated")
    func decodedBagCanBeMutated() throws {
        let original = MoneyBag().adding(Money<TST_100>(minorUnits: 300))
        let data = try encoder.encode(original)
        var decoded = try decoder.decode(MoneyBag.self, from: data)
        decoded.add(Money<TST_100>(minorUnits: 200))
        let amount = try #require(decoded.amount(in: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 500))
    }

    // MARK: - Malformed input

    @Test("Decoding JSON that is missing 'entries' key throws")
    func missingEntriesKeyThrows() throws {
        let json = #"{"other":[]}"#
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try decoder.decode(MoneyBag.self, from: data)
        }
    }

    @Test("Decoding JSON with duplicate currency codes throws")
    func duplicateCurrencyCodesThrow() throws {
        // Manually craft JSON with two entries for the same currency code
        let json = """
        {"entries":[
            {"minorUnits":100,"currencyCode":"TST_100","minimalQuantisation":100},
            {"minorUnits":200,"currencyCode":"TST_100","minimalQuantisation":100}
        ]}
        """
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try decoder.decode(MoneyBag.self, from: data)
        }
    }
}

// MARK: - .array strategy

@Suite("MoneyBag – Codable – .array strategy")
struct MoneyBag_CodableTests_ArrayStrategy {

    private let resolver: @Sendable (CurrencyCode) -> MinimalQuantisation? = { code in
        switch code.stringValue {
        case "TST_100": return 100
        case "TST_1": return 1
        default: return nil
        }
    }

    // MARK: Encoding shape

    @Test(".array: empty bag encodes to []")
    func emptyBagEncodesToArray() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .array(entry: .full)
        let json = try #require(String(data: enc.encode(MoneyBag()), encoding: .utf8))
        #expect(json == "[]")
    }

    @Test(".array(entry: .full): single entry JSON shape")
    func arrayFullSingleEntryShape() throws {
        var enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        enc.moneyBagEncodingStrategy = .array(entry: .full)
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let json = try #require(String(data: enc.encode(bag), encoding: .utf8))
        // sortedKeys: currencyCode < minimalQuantisation < minorUnits
        #expect(json == #"[{"currencyCode":"TST_100","minimalQuantisation":100,"minorUnits":500}]"#)
    }

    @Test(".array(entry: .object(minorUnits)): single entry JSON shape")
    func arrayObjectMinorUnitsSingleEntryShape() throws {
        var enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        enc.moneyBagEncodingStrategy = .array(entry: .object(amount: .minorUnits))
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let json = try #require(String(data: enc.encode(bag), encoding: .utf8))
        // sortedKeys: amount < currencyCode
        #expect(json == #"[{"amount":500,"currencyCode":"TST_100"}]"#)
    }

    // MARK: Round-trips

    @Test(".array(entry: .full): single entry round-trips")
    func arrayFullSingleEntryRoundTrip() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .array(entry: .full)
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .array(entry: .full)
        let original = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let decoded = try dec.decode(MoneyBag.self, from: enc.encode(original))
        #expect(decoded == original)
    }

    @Test(".array(entry: .full): multi-currency round-trips")
    func arrayFullMultiCurrencyRoundTrip() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .array(entry: .full)
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .array(entry: .full)
        let original = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 900))
        let decoded = try dec.decode(MoneyBag.self, from: enc.encode(original))
        #expect(decoded == original)
    }

    @Test(".array(entry: .object(majorUnits)): round-trips with resolver")
    func arrayObjectMajorUnitsRoundTrip() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .array(entry: .object(amount: .majorUnits))
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .array(entry: .object(amount: .majorUnits, resolver: resolver))
        let original = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 900))
        let decoded = try dec.decode(MoneyBag.self, from: enc.encode(original))
        #expect(decoded == original)
    }

    @Test(".array static shorthand (.full entries) round-trips")
    func arrayStaticShorthandRoundTrip() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .array
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .array
        let original = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let decoded = try dec.decode(MoneyBag.self, from: enc.encode(original))
        #expect(decoded == original)
    }

    @Test(".array: empty bag decodes from []")
    func emptyArrayDecodes() throws {
        let data = try #require("[]".data(using: .utf8))
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .array(entry: .full)
        #expect(try dec.decode(MoneyBag.self, from: data).isEmpty)
    }

    @Test(".array: duplicate currency codes in array throw")
    func arrayDuplicateCurrencyCodesThrow() throws {
        let json = """
        [
            {"currencyCode":"TST_100","minimalQuantisation":100,"minorUnits":100},
            {"currencyCode":"TST_100","minimalQuantisation":100,"minorUnits":200}
        ]
        """
        let data = try #require(json.data(using: .utf8))
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .array(entry: .full)
        #expect(throws: (any Error).self) {
            try dec.decode(MoneyBag.self, from: data)
        }
    }
}

// MARK: - .dictionary strategy

@Suite("MoneyBag – Codable – .dictionary strategy")
struct MoneyBag_CodableTests_DictionaryStrategy {

    private let resolver: @Sendable (CurrencyCode) -> MinimalQuantisation? = { code in
        switch code.stringValue {
        case "TST_100": return 100
        case "TST_1": return 1
        default: return nil
        }
    }

    // MARK: Encoding shape

    @Test(".dictionary: empty bag encodes to {}")
    func emptyBagEncodesToEmptyObject() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .dictionary(amount: .minorUnits)
        let json = try #require(String(data: enc.encode(MoneyBag()), encoding: .utf8))
        #expect(json == "{}")
    }

    @Test(".dictionary(minorUnits): single entry JSON shape")
    func dictionaryMinorUnitsSingleEntryShape() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .dictionary(amount: .minorUnits)
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let json = try #require(String(data: enc.encode(bag), encoding: .utf8))
        #expect(json == #"{"TST_100":500}"#)
    }

    @Test(".dictionary(minorUnits): multi-currency JSON keys are sorted")
    func dictionaryMinorUnitsMultiCurrencyShape() throws {
        var enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        enc.moneyBagEncodingStrategy = .dictionary(amount: .minorUnits)
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 900))
        let json = try #require(String(data: enc.encode(bag), encoding: .utf8))
        // sortedKeys: "TST_1" < "TST_100"
        #expect(json == #"{"TST_1":900,"TST_100":500}"#)
    }

    // MARK: Round-trips

    @Test(".dictionary(minorUnits): round-trips with resolver")
    func dictionaryMinorUnitsRoundTrip() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .dictionary(amount: .minorUnits)
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .dictionary(amount: .minorUnits, resolver: resolver)
        let original = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 900))
        let decoded = try dec.decode(MoneyBag.self, from: enc.encode(original))
        #expect(decoded == original)
    }

    @Test(".dictionary(majorUnits): round-trips with resolver")
    func dictionaryMajorUnitsRoundTrip() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .dictionary(amount: .majorUnits)
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .dictionary(amount: .majorUnits, resolver: resolver)
        let original = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 900))
        let decoded = try dec.decode(MoneyBag.self, from: enc.encode(original))
        #expect(decoded == original)
    }

    @Test(".dictionary(majorUnits): negative amount round-trips")
    func dictionaryMajorUnitsNegativeRoundTrip() throws {
        var enc = JSONEncoder()
        enc.moneyBagEncodingStrategy = .dictionary(amount: .majorUnits)
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .dictionary(amount: .majorUnits, resolver: resolver)
        let original = MoneyBag().subtracting(Money<TST_100>(minorUnits: 250))
        let decoded = try dec.decode(MoneyBag.self, from: enc.encode(original))
        #expect(decoded == original)
    }

    @Test(".dictionary: resolver returning nil throws DecodingError")
    func dictionaryResolverNilThrows() throws {
        let json = #"{"UNKNOWN":5}"#
        let data = try #require(json.data(using: .utf8))
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .dictionary(amount: .minorUnits, resolver: { _ in nil })
        #expect(throws: DecodingError.self) {
            try dec.decode(MoneyBag.self, from: data)
        }
    }

    @Test(".dictionary: empty bag decodes from {}")
    func emptyObjectDecodes() throws {
        let data = try #require("{}".data(using: .utf8))
        var dec = JSONDecoder()
        dec.moneyBagDecodingStrategy = .dictionary(amount: .minorUnits, resolver: resolver)
        #expect(try dec.decode(MoneyBag.self, from: data).isEmpty)
    }
}

// MARK: - Strategy property API

@Suite("MoneyBag – Codable – Strategy property API")
struct MoneyBag_CodableTests_StrategyAPI {

    @Test("JSONEncoder.moneyBagEncodingStrategy defaults to .full")
    func encoderDefaultStrategyIsFull() throws {
        let encoder = JSONEncoder()
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let json = try #require(String(data: encoder.encode(bag), encoding: .utf8))
        // .full produces {"entries":[...]}, .array produces [...]
        #expect(json.contains("\"entries\""))
    }

    @Test("JSONEncoder.moneyBagEncodingStrategy setter is respected")
    func encoderStrategySetterRespected() throws {
        var encoder = JSONEncoder()
        encoder.moneyBagEncodingStrategy = .array(entry: .full)
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let json = try #require(String(data: encoder.encode(bag), encoding: .utf8))
        #expect(json.hasPrefix("["))
        #expect(!json.contains("\"entries\""))
    }

    @Test("JSONDecoder.moneyBagDecodingStrategy defaults to .full")
    func decoderDefaultStrategyIsFull() throws {
        let fullJSON = #"{"entries":[{"minorUnits":500,"currencyCode":"TST_100","minimalQuantisation":100}]}"#
        let data = try #require(fullJSON.data(using: .utf8))
        let bag = try JSONDecoder().decode(MoneyBag.self, from: data)
        let amount = try #require(bag.amount(in: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 500))
    }

    @Test("JSONDecoder.moneyBagDecodingStrategy setter is respected")
    func decoderStrategySetterRespected() throws {
        let arrayJSON = #"[{"minorUnits":500,"currencyCode":"TST_100","minimalQuantisation":100}]"#
        let data = try #require(arrayJSON.data(using: .utf8))
        var decoder = JSONDecoder()
        decoder.moneyBagDecodingStrategy = .array(entry: .full)
        let bag = try decoder.decode(MoneyBag.self, from: data)
        let amount = try #require(bag.amount(in: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 500))
    }
}
