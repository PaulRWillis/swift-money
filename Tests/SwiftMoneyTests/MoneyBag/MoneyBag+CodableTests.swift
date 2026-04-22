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
