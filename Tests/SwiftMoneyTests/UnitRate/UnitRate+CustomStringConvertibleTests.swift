import Testing
import SwiftMoney

@Suite("UnitRate - CustomStringConvertible")
struct UnitRateCustomStringConvertibleTests {

    // MARK: - description delegates to formatted()

    @Test("description equals formatted() output")
    func descriptionEqualsFormatted() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        #expect(unitRate.description == unitRate.formatted())
    }

    @Test("description includes unit label")
    func descriptionIncludesUnit() throws {
        let rate = try #require(Rate(numerator: 14500, denominator: 200))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel")
        #expect(unitRate.description.hasSuffix("/barrel"))
    }

    @Test("description with zero rate")
    func descriptionZeroRate() throws {
        let unitRate = UnitRate<GBP, String>(.zero, per: "kWh")
        #expect(unitRate.description == unitRate.formatted())
    }

    @Test("description with multi-word unit")
    func descriptionMultiWordUnit() throws {
        let rate = try #require(Rate(numerator: 50, denominator: 1))
        let unitRate = UnitRate<USD, String>(rate, per: "barrel of oil")
        #expect(unitRate.description.hasSuffix("/barrel of oil"))
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
}
