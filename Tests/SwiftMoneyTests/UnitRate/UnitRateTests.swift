import Testing
import SwiftMoney

@Suite("UnitRate")
struct UnitRateTests {

    // MARK: - Construction

    @Test("init(_ rate:per:) stores rate and unit")
    func initStoresRateAndUnit() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.rate == rate)
        #expect(unitRate.unit == "kWh")
    }

    @Test("init(_ rate:per:) with negative rate succeeds (feed-in tariff)")
    func negativeRateSucceeds() throws {
        let rate = try #require(Rate(numerator: -5, denominator: 100))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.rate == rate)
    }

    @Test("init(_ rate:per:) with zero rate succeeds (free)")
    func zeroRateSucceeds() throws {
        let rate = try #require(Rate(numerator: 0, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.rate == rate)
    }

    @Test("init?(numerator:denominator:per:) succeeds for valid inputs")
    func failableInitSucceeds() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        let expectedRate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        #expect(unitRate.rate == expectedRate)
        #expect(unitRate.unit == "kWh")
    }

    @Test("init?(numerator:denominator:per:) returns nil for zero denominator")
    func failableInitNilForZeroDenominator() {
        let unitRate = UnitRate<GBP, String>(numerator: 1, denominator: 0, per: "kWh")
        #expect(unitRate == nil)
    }

    @Test("init?(numerator:denominator:per:) returns nil for negative denominator")
    func failableInitNilForNegativeDenominator() {
        let unitRate = UnitRate<GBP, String>(numerator: 1, denominator: -1, per: "kWh")
        #expect(unitRate == nil)
    }

    @Test("init?(numerator:denominator:per:) returns nil for Int64.min numerator")
    func failableInitNilForMinNumerator() {
        let unitRate = UnitRate<GBP, String>(numerator: .min, denominator: 1, per: "kWh")
        #expect(unitRate == nil)
    }

    // MARK: - Equatable

    @Test("Same rate and same unit are equal")
    func sameRateSameUnitAreEqual() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let a = UnitRate<GBP, String>(rate, per: "kWh")
        let b = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(a == b)
    }

    @Test("Same rate but different unit are NOT equal")
    func sameRateDifferentUnitNotEqual() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let a = UnitRate<GBP, String>(rate, per: "kWh")
        let b = UnitRate<GBP, String>(rate, per: "MWh")
        #expect(a != b)
    }

    @Test("Different rate but same unit are not equal")
    func differentRateSameUnitNotEqual() throws {
        let rateA = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let rateB = try #require(Rate(numerator: 46, denominator: 1_000_000))
        let a = UnitRate<GBP, String>(rateA, per: "kWh")
        let b = UnitRate<GBP, String>(rateB, per: "kWh")
        #expect(a != b)
    }

    @Test("GCD-reduced rates compare equal")
    func gcdReducedRatesEqual() throws {
        let rateA = try #require(Rate(numerator: 46, denominator: 2_000_000))
        let rateB = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let a = UnitRate<GBP, String>(rateA, per: "kWh")
        let b = UnitRate<GBP, String>(rateB, per: "kWh")
        #expect(a == b)
    }

    // MARK: - Hashable

    @Test("Equal UnitRates deduplicate in a Set")
    func hashableDeduplication() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let a = UnitRate<GBP, String>(rate, per: "kWh")
        let b = UnitRate<GBP, String>(rate, per: "kWh")
        let set: Set<UnitRate<GBP, String>> = [a, b]
        #expect(set.count == 1)
    }

    @Test("Distinct UnitRates coexist in a Set")
    func hashableDistinct() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let a = UnitRate<GBP, String>(rate, per: "kWh")
        let b = UnitRate<GBP, String>(rate, per: "MWh")
        let set: Set<UnitRate<GBP, String>> = [a, b]
        #expect(set.count == 2)
    }

    @Test("UnitRate can be used as a Dictionary key")
    func dictionaryKey() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let key = UnitRate<GBP, String>(rate, per: "kWh")
        var dict: [UnitRate<GBP, String>: Int] = [:]
        dict[key] = 42
        #expect(dict[key] == 42)
    }

    // MARK: - Sendable

    @Test("UnitRate is Sendable")
    func isSendable() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let _: any Sendable = unitRate
    }
}
