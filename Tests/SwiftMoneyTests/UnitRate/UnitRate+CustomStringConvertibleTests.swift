import Testing
import SwiftMoney

@Suite("UnitRate - CustomStringConvertible")
struct UnitRateCustomStringConvertibleTests {

    // MARK: - description (String unit)

    @Test("description shows rate and string unit")
    func descriptionBasic() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.description == "23/1000000/kWh")
    }

    @Test("description with GCD-reduced rate shows reduced form")
    func descriptionGCDReduced() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        #expect(unitRate.description == "145/2/barrel")
    }

    @Test("description with negative rate includes minus sign")
    func descriptionNegativeRate() throws {
        let rate = try #require(Rate(numerator: -5, denominator: 100))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.description == "-1/20/kWh")
    }

    @Test("description with zero rate shows 0/1")
    func descriptionZeroRate() throws {
        let unitRate = UnitRate<GBP, String>(.zero, per: "kWh")
        #expect(unitRate.description == "0/1/kWh")
    }

    @Test("description with denominator 1 shows /1")
    func descriptionDenominator1() throws {
        let rate = try #require(Rate(numerator: 100, denominator: 1))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        #expect(unitRate.description == "100/1/barrel")
    }

    @Test("description with multi-word unit")
    func descriptionMultiWordUnit() throws {
        let rate = try #require(Rate(numerator: 50, denominator: 1))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel of oil")
        #expect(unitRate.description == "50/1/barrel of oil")
    }

    @Test("description with empty string unit")
    func descriptionEmptyUnit() throws {
        let rate = try #require(Rate(numerator: 1, denominator: 1))
        let unitRate = UnitRate<GBP, String>(rate, per: "")
        #expect(unitRate.description == "1/1/")
    }

    @Test("description uses String(describing:) for CustomStringConvertible unit")
    func descriptionCustomUnit() throws {
        let rate = try #require(Rate(numerator: 7, denominator: 10))
        let unitRate = UnitRate<USD, String>(rate, per: "litre")
        #expect(unitRate.description == "7/10/litre")
    }

    // MARK: - debugDescription

    @Test("debugDescription shows type info and rate")
    func debugDescriptionBasic() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.debugDescription == "UnitRate<GBP, String>(rate: 23/1000000, per: \"kWh\")")
    }

    @Test("debugDescription with negative rate")
    func debugDescriptionNegative() throws {
        let rate = try #require(Rate(numerator: -5, denominator: 100))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.debugDescription == "UnitRate<GBP, String>(rate: -1/20, per: \"kWh\")")
    }

    // MARK: - description delegates to formatted()

    @Test("description equals formatted() output")
    func descriptionEqualsFormatted() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.description == unitRate.formatted())
    }
}
