import Foundation
import Testing
import SwiftMoney

@Suite("ExchangeRate")
struct ExchangeRateTests {

    // MARK: - Initialisation

    @Test("init stores rate as FractionalRate(numerator: to, denominator: from)")
    func initStoresRate() {
        let r = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        // 85/100 GCD-reduces to 17/20
        #expect(r.rate == FractionalRate(numerator: 17, denominator: 20)!)
    }

    @Test("fromMinorUnits and toMinorUnits reflect GCD-reduced values")
    func reducedProperties() {
        let r = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        #expect(r.fromMinorUnits == 20)
        #expect(r.toMinorUnits == 17)
    }

    @Test("GCD reduction: init(from:200, to:170) == init(from:20, to:17)")
    func gcdReductionEquality() {
        let r1 = ExchangeRate<EUR, GBP>(from: 200, to: 170)!
        let r2 = ExchangeRate<EUR, GBP>(from: 20, to: 17)!
        #expect(r1 == r2)
    }

    @Test("Identity rate: 1:1 same currency")
    func identityRate() {
        let r = ExchangeRate<GBP, GBP>(from: 1, to: 1)!
        #expect(r.fromMinorUnits == 1)
        #expect(r.toMinorUnits == 1)
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
    func basicConversion() {
        let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        let result = rate.convert(Money<EUR>(minorUnits: 1000))
        #expect(result == Money<GBP>(minorUnits: 850))
    }

    @Test("Zero input converts to zero")
    func zeroInput() {
        let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        #expect(rate.convert(.zero) == .zero)
    }

    @Test("Identity rate preserves amount")
    func identityConversion() {
        let rate = ExchangeRate<GBP, GBP>(from: 1, to: 1)!
        let money = Money<GBP>(minorUnits: 12345)
        #expect(rate.convert(money) == money)
    }

    @Test("Rounding: 1 EUR minor unit × 17/20 = 0.85 → rounds to 1 (toNearestOrAwayFromZero)")
    func roundingOneMinorUnit() {
        let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        let result = rate.convert(Money<EUR>(minorUnits: 1))
        #expect(result == Money<GBP>(minorUnits: 1))
    }

    @Test("Rounding: 5 EUR minor units × 17/20 = 4.25 → rounds to 4 (toNearestOrAwayFromZero)")
    func roundingFiveMinorUnits() {
        let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        let result = rate.convert(Money<EUR>(minorUnits: 5))
        // 5 × 17/20 = 85/20 = 4.25 → rounds to 4
        #expect(result == Money<GBP>(minorUnits: 4))
    }

    @Test("Custom rounding rule: .up rounds 0.85 to 1")
    func customRoundingUp() {
        let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        let result = rate.convert(Money<EUR>(minorUnits: 1), rounding: .up)
        #expect(result == Money<GBP>(minorUnits: 1))
    }

    @Test("Custom rounding rule: .down rounds 0.85 to 0")
    func customRoundingDown() {
        let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        let result = rate.convert(Money<EUR>(minorUnits: 1), rounding: .down)
        #expect(result == Money<GBP>(minorUnits: 0))
    }

    @Test("NaN input traps")
    func nanInputTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = ExchangeRate<EUR, GBP>(from: 100, to: 85)!.convert(.nan)
        }
    }

    // MARK: - Equatable & Hashable

    @Test("Equal rates have equal hashes")
    func hashableTest() {
        let r1 = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        let r2 = ExchangeRate<EUR, GBP>(from: 20, to: 17)!
        #expect(r1.hashValue == r2.hashValue)
    }

    @Test("Different rates are not equal")
    func inequalityTest() {
        let r1 = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        let r2 = ExchangeRate<EUR, GBP>(from: 100, to: 90)!
        #expect(r1 != r2)
    }

    // MARK: - CustomStringConvertible

    @Test("description reflects GCD-reduced pair with currency codes")
    func descriptionTest() {
        let r = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        // 85/100 reduces to 17/20
        #expect(r.description == "20 EUR = 17 GBP")
    }

    @Test("description: exact pair (no reduction needed)")
    func descriptionNoReduction() {
        let r = ExchangeRate<USD, JPY>(from: 1, to: 150)!
        #expect(r.description == "1 USD = 150 JPY")
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves equality")
    func codableRoundTrip() throws {
        let original = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ExchangeRate<EUR, GBP>.self, from: data)
        #expect(original == decoded)
    }

    @Test("Codable encodes GCD-reduced fromMinorUnits and toMinorUnits")
    func codableEncodesReducedValues() throws {
        let r = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
        let data = try JSONEncoder().encode(r)
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

    // MARK: - init?(majorUnitRate: FractionalRate)

    @Test("GBP/JPY 21516/100 (215.16) scales to 5379/2500 minor-unit rate")
    func gbpJpyFractionalRate() throws {
        // majorUnitRate = 21516/100 (= 5379/25 after GCD)
        // toMinQ (JPY) = 1, fromMinQ (GBP) = 100
        // scaledNumerator = 5379 × 1 = 5379
        // scaledDenominator = 25 × 100 = 2500
        let rate = try #require(ExchangeRate<GBP, JPY>(
            majorUnitRate: FractionalRate(numerator: 21516, denominator: 100)!
        ))
        #expect(rate.toMinorUnits == 5379)
        #expect(rate.fromMinorUnits == 2500)
    }

    @Test("GBP/JPY 215.16: convert £1.00 (100p) gives 215 JPY")
    func gbpJpyConversionRoundsDown() throws {
        // 100p × 5379/2500 = 537900/2500 = 215.16 → rounds to 215
        let rate = try #require(ExchangeRate<GBP, JPY>(
            majorUnitRate: FractionalRate(numerator: 21516, denominator: 100)!
        ))
        #expect(rate.convert(Money<GBP>(minorUnits: 100)) == Money<JPY>(minorUnits: 215))
    }

    @Test("GBP/JPY 215.16: convert £100.00 (10000p) gives 21516 JPY (exact)")
    func gbpJpyConversionExact() throws {
        let rate = try #require(ExchangeRate<GBP, JPY>(
            majorUnitRate: FractionalRate(numerator: 21516, denominator: 100)!
        ))
        #expect(rate.convert(Money<GBP>(minorUnits: 10000)) == Money<JPY>(minorUnits: 21516))
    }

    @Test("GBP/USD 27/20 (1.35): both 100-minQ; rate equals major-unit rate")
    func gbpUsdEqualMinQ() throws {
        // majorUnitRate = 27/20 (= 1.35)
        // toMinQ (USD) = 100, fromMinQ (GBP) = 100
        // scaledNumerator = 27 × 100 = 2700, scaledDenominator = 20 × 100 = 2000 → 27/20
        let rate = try #require(ExchangeRate<GBP, USD>(
            majorUnitRate: FractionalRate(numerator: 27, denominator: 20)!
        ))
        // convert £1.00 (100p) → 100 × 27/20 = 135 cents = $1.35
        #expect(rate.convert(Money<GBP>(minorUnits: 100)) == Money<USD>(minorUnits: 135))
    }

    @Test("majorUnitRate returns nil for non-positive numerator")
    func negativeNumeratorIsNil() {
        #expect(ExchangeRate<EUR, GBP>(
            majorUnitRate: FractionalRate(numerator: -1, denominator: 10)!
        ) == nil)
    }

    @Test("majorUnitRate with integer literal 1 produces identity-like rate")
    func integerLiteralOne() throws {
        // majorUnitRate = 1/1; GBP/GBP (minQ 100/100 = 1 scale)
        // 1 × 100 / 1 × 100 = 100/100 = 1/1
        let rate = try #require(ExchangeRate<GBP, GBP>(majorUnitRate: FractionalRate(numerator: 1, denominator: 1)!))
        #expect(rate.convert(Money<GBP>(minorUnits: 100)) == Money<GBP>(minorUnits: 100))
    }

    // MARK: - init?(majorUnitRate: Decimal)

    @Test("GBP/JPY Decimal(string:\"215.16\") produces same rate as FractionalRate overload")
    func decimalMatchesFractionalRate() throws {
        let viaDecimal = try #require(
            ExchangeRate<GBP, JPY>(majorUnitRate: Decimal(string: "215.16")!)
        )
        let viaFractional = try #require(
            ExchangeRate<GBP, JPY>(majorUnitRate: FractionalRate(numerator: 21516, denominator: 100)!)
        )
        #expect(viaDecimal == viaFractional)
    }

    @Test("GBP/USD Decimal(string:\"1.35\") converts £1.00 to $1.35")
    func decimalGbpUsd() throws {
        let rate = try #require(ExchangeRate<GBP, USD>(majorUnitRate: Decimal(string: "1.35")!))
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
    func decimalNegativeIsNil() {
        #expect(ExchangeRate<GBP, JPY>(majorUnitRate: Decimal(string: "-1.0")!) == nil)
    }
}
