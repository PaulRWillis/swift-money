import Foundation
import Testing
import SwiftMoney

@Suite("ExchangeRate")
struct ExchangeRateTests {

    // MARK: - Initialisation

    @Test("init stores rate as Rate(numerator: to, denominator: from)")
    func initStoresRate() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        // 85/100 GCD-reduces to 17/20
        let expectedRate = try #require(Rate(numerator: 17, denominator: 20))
        #expect(rate.rate == expectedRate)
    }

    @Test("fromMinorUnits and toMinorUnits reflect GCD-reduced values")
    func reducedProperties() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        #expect(rate.fromMinorUnits == 20)
        #expect(rate.toMinorUnits == 17)
    }

    @Test("GCD reduction: init(from:200, to:170) == init(from:20, to:17)")
    func gcdReductionEquality() throws {
        let r1 = try #require(ExchangeRate<EUR, GBP>(from: 200, to: 170))
        let r2 = try #require(ExchangeRate<EUR, GBP>(from: 20, to: 17))
        #expect(r1 == r2)
    }

    @Test("Identity rate: 1:1 same currency")
    func identityRate() throws {
        let rate = try #require(ExchangeRate<GBP, GBP>(from: 1, to: 1))
        #expect(rate.fromMinorUnits == 1)
        #expect(rate.toMinorUnits == 1)
    }

    // MARK: - Failable init

    @Test("init returns nil for fromMinorUnits == 0")
    func fromMinorUnitsZeroIsNil() {
        #expect(ExchangeRate<EUR, GBP>(from: 0, to: 85) == nil)
    }

    @Test("init returns nil for fromMinorUnits < 0")
    func fromMinorUnitsNegativeIsNil() {
        #expect(ExchangeRate<EUR, GBP>(from: -1, to: 85) == nil)
    }

    @Test("init returns nil for toMinorUnits == 0")
    func toMinorUnitsZeroIsNil() {
        #expect(ExchangeRate<EUR, GBP>(from: 100, to: 0) == nil)
    }

    @Test("init returns nil for toMinorUnits < 0")
    func toMinorUnitsNegativeIsNil() {
        #expect(ExchangeRate<EUR, GBP>(from: 100, to: -1) == nil)
    }

    // MARK: - Conversion

    @Test("€10.00 (1000 minor units) × 85/100 = £8.50 (850 minor units)")
    func basicConversion() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        let result = rate.convert(Money<EUR>(minorUnits: 1000))
        #expect(result == Money<GBP>(minorUnits: 850))
    }

    @Test("Zero input converts to zero")
    func zeroInput() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        #expect(rate.convert(.zero) == .zero)
    }

    @Test("Identity rate preserves amount")
    func identityConversion() throws {
        let rate = try #require(ExchangeRate<GBP, GBP>(from: 1, to: 1))
        let money = Money<GBP>(minorUnits: 12345)
        #expect(rate.convert(money) == money)
    }

    @Test("Rounding: 1 EUR minor unit × 17/20 = 0.85 → rounds to 1 (toNearestOrAwayFromZero)")
    func roundingOneMinorUnit() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        let result = rate.convert(Money<EUR>(minorUnits: 1))
        #expect(result == Money<GBP>(minorUnits: 1))
    }

    @Test("Rounding: 5 EUR minor units × 17/20 = 4.25 → rounds to 4 (toNearestOrAwayFromZero)")
    func roundingFiveMinorUnits() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        let result = rate.convert(Money<EUR>(minorUnits: 5))
        // 5 × 17/20 = 85/20 = 4.25 → rounds to 4
        #expect(result == Money<GBP>(minorUnits: 4))
    }

    @Test("Custom rounding rule: .up rounds 0.85 to 1")
    func customRoundingUp() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        let result = rate.convert(Money<EUR>(minorUnits: 1), rounding: .up)
        #expect(result == Money<GBP>(minorUnits: 1))
    }

    @Test("Custom rounding rule: .down rounds 0.85 to 0")
    func customRoundingDown() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        let result = rate.convert(Money<EUR>(minorUnits: 1), rounding: .down)
        #expect(result == Money<GBP>(minorUnits: 0))
    }

    @Test("NaN input traps")
    func nanInputTraps() async {
        await #expect(processExitsWith: .failure) {
            guard let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85) else { return }
            _ = rate.convert(.nan)
        }
    }

    // MARK: - Equatable & Hashable

    @Test("Equal rates have equal hashes")
    func hashableTest() throws {
        let r1 = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        let r2 = try #require(ExchangeRate<EUR, GBP>(from: 20, to: 17))
        #expect(r1.hashValue == r2.hashValue)
    }

    @Test("Different rates are not equal")
    func inequalityTest() throws {
        let r1 = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        let r2 = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 90))
        #expect(r1 != r2)
    }

    // MARK: - CustomStringConvertible

    @Test("description reflects GCD-reduced pair with currency codes")
    func descriptionTest() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        // 85/100 reduces to 17/20
        #expect(rate.description == "20 EUR = 17 GBP")
    }

    @Test("description: exact pair (no reduction needed)")
    func descriptionNoReduction() throws {
        let rate = try #require(ExchangeRate<USD, JPY>(from: 1, to: 150))
        #expect(rate.description == "1 USD = 150 JPY")
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves equality")
    func codableRoundTrip() throws {
        let original = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ExchangeRate<EUR, GBP>.self, from: data)
        #expect(original == decoded)
    }

    @Test("Codable encodes GCD-reduced fromMinorUnits and toMinorUnits")
    func codableEncodesReducedValues() throws {
        let rate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        let data = try JSONEncoder().encode(rate)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Int64]
        #expect(json?["fromMinorUnits"] == 20)
        #expect(json?["toMinorUnits"] == 17)
    }

    @Test("Codable: rejects fromMinorUnits == 0")
    func codableRejectsZeroFrom() {
        let json = #"{"fromMinorUnits": 0, "toMinorUnits": 85}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ExchangeRate<EUR, GBP>.self, from: Data(json.utf8))
        }
    }

    @Test("Codable: rejects toMinorUnits == 0")
    func codableRejectsZeroTo() {
        let json = #"{"fromMinorUnits": 100, "toMinorUnits": 0}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ExchangeRate<EUR, GBP>.self, from: Data(json.utf8))
        }
    }

    @Test("Codable: rejects negative fromMinorUnits")
    func codableRejectsNegativeFrom() {
        let json = #"{"fromMinorUnits": -1, "toMinorUnits": 85}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ExchangeRate<EUR, GBP>.self, from: Data(json.utf8))
        }
    }
}

// MARK: - majorUnitRate initialisers

@Suite("ExchangeRate - majorUnitRate initialisers")
struct ExchangeRate_MajorUnitRateTests {

    // MARK: - init?(majorUnitRate: Rate)

    @Test("GBP/JPY 21516/100 (215.16) scales to 5379/2500 minor-unit rate")
    func gbpJpyRate() throws {
        let majorRate = try #require(Rate(numerator: 21516, denominator: 100))
        let rate = try #require(ExchangeRate<GBP, JPY>(majorUnitRate: majorRate))
        #expect(rate.toMinorUnits == 5379)
        #expect(rate.fromMinorUnits == 2500)
    }

    @Test("GBP/JPY 215.16: convert £1.00 (100p) gives 215 JPY")
    func gbpJpyConversionRoundsDown() throws {
        let majorRate = try #require(Rate(numerator: 21516, denominator: 100))
        let rate = try #require(ExchangeRate<GBP, JPY>(majorUnitRate: majorRate))
        #expect(rate.convert(Money<GBP>(minorUnits: 100)) == Money<JPY>(minorUnits: 215))
    }

    @Test("GBP/JPY 215.16: convert £100.00 (10000p) gives 21516 JPY (exact)")
    func gbpJpyConversionExact() throws {
        let majorRate = try #require(Rate(numerator: 21516, denominator: 100))
        let rate = try #require(ExchangeRate<GBP, JPY>(majorUnitRate: majorRate))
        #expect(rate.convert(Money<GBP>(minorUnits: 10000)) == Money<JPY>(minorUnits: 21516))
    }

    @Test("GBP/USD 27/20 (1.35): both 100-minQ; rate equals major-unit rate")
    func gbpUsdEqualMinQ() throws {
        let majorRate = try #require(Rate(numerator: 27, denominator: 20))
        let rate = try #require(ExchangeRate<GBP, USD>(majorUnitRate: majorRate))
        #expect(rate.convert(Money<GBP>(minorUnits: 100)) == Money<USD>(minorUnits: 135))
    }

    @Test("majorUnitRate returns nil for non-positive numerator")
    func negativeNumeratorIsNil() throws {
        let negativeRate = try #require(Rate(numerator: -1, denominator: 10))
        #expect(ExchangeRate<EUR, GBP>(majorUnitRate: negativeRate) == nil)
    }

    @Test("majorUnitRate with integer literal 1 produces identity-like rate")
    func integerLiteralOne() throws {
        let majorRate = try #require(Rate(numerator: 1, denominator: 1))
        let rate = try #require(ExchangeRate<GBP, GBP>(majorUnitRate: majorRate))
        #expect(rate.convert(Money<GBP>(minorUnits: 100)) == Money<GBP>(minorUnits: 100))
    }

    // MARK: - init?(majorUnitRate: Decimal)

    @Test("GBP/JPY Decimal(string:\"215.16\") produces same rate as Rate overload")
    func decimalMatchesRate() throws {
        let decimal = try #require(Decimal(string: "215.16"))
        let viaDecimal = try #require(ExchangeRate<GBP, JPY>(majorUnitRate: decimal))
        let majorRate = try #require(Rate(numerator: 21516, denominator: 100))
        let viaFractional = try #require(ExchangeRate<GBP, JPY>(majorUnitRate: majorRate))
        #expect(viaDecimal == viaFractional)
    }

    @Test("GBP/USD Decimal(string:\"1.35\") converts £1.00 to $1.35")
    func decimalGbpUsd() throws {
        let decimal = try #require(Decimal(string: "1.35"))
        let rate = try #require(ExchangeRate<GBP, USD>(majorUnitRate: decimal))
        #expect(rate.convert(Money<GBP>(minorUnits: 100)) == Money<USD>(minorUnits: 135))
    }

    @Test("Decimal NaN majorUnitRate returns nil")
    func decimalNaNIsNil() {
        #expect(ExchangeRate<GBP, JPY>(majorUnitRate: Decimal.nan) == nil)
    }

    @Test("Decimal zero majorUnitRate returns nil")
    func decimalZeroIsNil() {
        #expect(ExchangeRate<GBP, JPY>(majorUnitRate: Decimal(0)) == nil)
    }

    @Test("Decimal negative majorUnitRate returns nil")
    func decimalNegativeIsNil() throws {
        let decimal = try #require(Decimal(string: "-1.0"))
        #expect(ExchangeRate<GBP, JPY>(majorUnitRate: decimal) == nil)
    }
}
