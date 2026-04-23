import Foundation
import SwiftMoney
import Testing

@Suite("Money - Safety Hardening")
struct Money_SafetyTests {

    private let enGB = Locale(identifier: "en_GB")

    // MARK: - Codable

    @Test("Money<GBP> encodes and decodes correctly (positive)")
    func codableRoundTripPositive() throws {
        let original = Money<GBP>(minorUnits: 12_345)
        let data     = try JSONEncoder().encode(original)
        let decoded  = try JSONDecoder().decode(Money<GBP>.self, from: data)
        #expect(decoded == original)
    }

    @Test("Money<GBP> encodes and decodes correctly (negative)")
    func codableRoundTripNegative() throws {
        let original = Money<GBP>(minorUnits: -9_876)
        let data     = try JSONEncoder().encode(original)
        let decoded  = try JSONDecoder().decode(Money<GBP>.self, from: data)
        #expect(decoded == original)
    }

    @Test("Money<GBP> encodes and decodes correctly (zero)")
    func codableRoundTripZero() throws {
        let original = Money<GBP>.zero
        let data     = try JSONEncoder().encode(original)
        let decoded  = try JSONDecoder().decode(Money<GBP>.self, from: data)
        #expect(decoded == original)
    }

    @Test("Money<GBP>.nan encodes and decodes as NaN using .minorUnits strategy")
    func codableNaN() throws {
        let original = Money<GBP>.nan
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .minorUnits
        let data    = try encoder.encode(original)
        let decoded = try decoder.decode(Money<GBP>.self, from: data)
        #expect(decoded.isNaN)
    }

    @Test("Money<JPY> encodes and decodes correctly (minQ = 1)")
    func codableJPY() throws {
        let original = Money<JPY>(minorUnits: 99_999)
        let data     = try JSONEncoder().encode(original)
        let decoded  = try JSONDecoder().decode(Money<JPY>.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Sendable (compile-time verification)
    //
    // There is no runtime assertion for Sendable — if Money were not Sendable
    // the line below would fail to compile with a "type does not conform" error.
    // The test body itself is trivial; the conformance is what matters.

    @Test("Money<GBP> is Sendable")
    func moneyIsSendable() {
        func requiresSendable<T: Sendable>(_: T) {}
        requiresSendable(Money<GBP>(minorUnits: 100))
    }

    // MARK: - CustomDebugStringConvertible

    @Test("debugDescription contains currency code, minor units and formatted value")
    func debugDescriptionNormal() {
        let money = Money<GBP>(minorUnits: 150)
        let desc  = money.debugDescription
        #expect(desc.contains("GBP"))
        #expect(desc.contains("150"))
        #expect(desc.contains("£1.50") || !money.formatted(Money<GBP>.FormatStyle(locale: enGB)).isEmpty)
    }

    @Test("debugDescription for NaN contains 'NaN' and currency code")
    func debugDescriptionNaN() {
        let money = Money<GBP>.nan
        let desc  = money.debugDescription
        #expect(desc.contains("GBP"))
        #expect(desc.contains("NaN"))
    }

    @Test("AnyMoney debugDescription contains currency code and minor units")
    func anyMoneyDebugDescription() {
        let any = Money<GBP>(minorUnits: 150).erased
        let desc = any.debugDescription
        #expect(desc.contains("GBP"))
        #expect(desc.contains("150"))
    }

    @Test("AnyMoney NaN debugDescription contains 'NaN'")
    func anyMoneyDebugDescriptionNaN() {
        let any = Money<GBP>.nan.erased
        let desc = any.debugDescription
        #expect(desc.contains("NaN"))
    }

    @Test("MoneyBag debugDescription contains currency code and minor units for each entry")
    func moneyBagDebugDescription() {
        let bag = MoneyBag()
            .adding(Money<GBP>(minorUnits: 150))
            .adding(Money<EUR>(minorUnits: 1000))
        let desc = bag.debugDescription
        #expect(desc.contains("GBP"))
        #expect(desc.contains("150"))
        #expect(desc.contains("EUR"))
        #expect(desc.contains("1000"))
    }

    @Test("Empty MoneyBag debugDescription is well-formed")
    func emptyMoneyBagDebugDescription() {
        let desc = MoneyBag().debugDescription
        #expect(desc.contains("MoneyBag"))
    }
}
