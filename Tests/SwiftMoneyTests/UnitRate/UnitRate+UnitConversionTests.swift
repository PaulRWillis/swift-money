#if canImport(Foundation)
import Foundation
import Testing
import SwiftMoney

@Suite("UnitRate - unit conversion")
struct UnitRate_UnitConversionTests {

    // MARK: - Exact integer factor conversion

    @Test("£0.000023/kWh converted to per-kJ divides rate by 3600")
    func kWhToKJExact() throws {
        // 23/1_000_000 per kWh → per kJ: rate × (1/3600) = 23/3_600_000_000
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let converted = rate.converted(to: .kilojoules, factor: 3600)
        let expected = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 3_600_000_000, per: .kilojoules))
        #expect(converted == expected)
    }

    @Test("$72.50/barrel converted to per-gallon (42 gal/bbl)")
    func barrelToGallon() throws {
        // 145/2 per barrel → per gallon: (145/2) / 42 = 145/84
        let rate = try #require(UnitRate<USD, UnitVolume>(numerator: 145, denominator: 2, per: .imperialGallons))
        let converted = rate.converted(to: .imperialPints, factor: 8)
        let expected = try #require(UnitRate<USD, UnitVolume>(numerator: 145, denominator: 16, per: .imperialPints))
        #expect(converted == expected)
    }

    @Test("factor of 1 returns equivalent UnitRate with new unit")
    func factorOne() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let converted = rate.converted(to: .kilowattHours, factor: 1)
        #expect(converted == rate)
    }

    @Test("zero rate remains zero after conversion")
    func zeroRate() {
        let rate = UnitRate<GBP, UnitEnergy>(.zero, per: .kilowattHours)
        let converted = rate.converted(to: .kilojoules, factor: 3600)
        #expect(converted.rate == .zero)
        #expect(converted.unit == .kilojoules)
    }

    @Test("negative rate converted correctly")
    func negativeRate() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: -23, denominator: 1_000_000, per: .kilowattHours))
        let converted = rate.converted(to: .kilojoules, factor: 3600)
        let expected = try #require(UnitRate<GBP, UnitEnergy>(numerator: -23, denominator: 3_600_000_000, per: .kilojoules))
        #expect(converted == expected)
    }

    // MARK: - Foundation auto-conversion

    @Test("auto-conversion kWh to kJ uses Foundation coefficient")
    func autoConvertKWhToKJ() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let converted = rate.converted(to: .kilojoules)
        let expected = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 3_600_000_000, per: .kilojoules))
        #expect(converted == expected)
    }

    @Test("auto-conversion returns nil for non-integer coefficient")
    func nonIntegerCoefficientReturnsNil() throws {
        // miles to meters: coefficient is 1609.344 (non-integer)
        let rate = try #require(UnitRate<USD, UnitLength>(numerator: 1, denominator: 1, per: .miles))
        #expect(rate.converted(to: .meters) == nil)
    }

    @Test("auto-conversion litres to millilitres (factor 1000)")
    func litresToMillilitres() throws {
        let rate = try #require(UnitRate<USD, UnitVolume>(numerator: 1, denominator: 2, per: .liters))
        let converted = rate.converted(to: .milliliters)
        let expected = try #require(UnitRate<USD, UnitVolume>(numerator: 1, denominator: 2000, per: .milliliters))
        #expect(converted == expected)
    }
}
#endif
