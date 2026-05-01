#if canImport(Foundation)
import Foundation
import Testing
import SwiftMoney

@Suite("UnitRate - price(for: Measurement)")
struct UnitRate_MeasurementTests {

    // MARK: - Basic conversion

    @Test("2_000_000 kWh measurement at £0.000023/kWh = £46.00")
    func basicKWh() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 2_000_000, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<GBP>(minorUnits: 4600))
    }

    // MARK: - Auto-conversion from different unit

    @Test("3_600_000 kJ auto-converts to 1000 kWh at £0.000023/kWh")
    func autoConvertsKJToKWh() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 3_600_000, unit: UnitEnergy.kilojoules)
        let result = try #require(rate.price(for: usage))
        // 3_600_000 kJ = 1000 kWh; 1000 × 23 × 100 / 1_000_000 = 2.3 → rounds to 2
        #expect(result.amount == Money<GBP>(minorUnits: 2))
    }

    @Test("500 litres at $0.50/litre = $250.00")
    func litres() throws {
        let rate = try #require(UnitRate<USD, UnitVolume>(numerator: 1, denominator: 2, per: .liters))
        let volume = Measurement(value: 500, unit: UnitVolume.liters)
        let result = try #require(rate.price(for: volume))
        #expect(result.amount == Money<USD>(minorUnits: 25_000))
    }

    @Test("0.5 cubic metres at $0.50/litre converts to 500 litres")
    func cubicMetresToLitres() throws {
        let rate = try #require(UnitRate<USD, UnitVolume>(numerator: 1, denominator: 2, per: .liters))
        let volume = Measurement(value: 0.5, unit: UnitVolume.cubicMeters)  // = 500 litres
        let result = try #require(rate.price(for: volume))
        #expect(result.amount == Money<USD>(minorUnits: 25_000))
    }

    // MARK: - Non-integer conversion returns nil

    @Test("returns nil when converted quantity is not an integer")
    func nonIntegerReturnsNil() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 1.5, unit: UnitEnergy.kilowattHours)
        #expect(rate.price(for: usage) == nil)
    }

    // MARK: - Zero measurement

    @Test("zero measurement returns zero amount")
    func zeroMeasurement() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 0, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<GBP>.zero)
    }

    // MARK: - Negative measurement (export/feed-in)

    @Test("negative measurement produces negative amount")
    func negativeMeasurement() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: -2_000_000, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<GBP>(minorUnits: -4600))
    }

    // MARK: - Rounding parameter passthrough

    @Test("rounding parameter is respected")
    func roundingUp() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 1, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage, rounding: .up))
        #expect(result.amount == Money<GBP>(minorUnits: 1))
    }

    // MARK: - Overflow from conversion returns nil

    @Test("returns nil when converted value overflows Int64")
    func overflowReturnsNil() throws {
        let rate = try #require(UnitRate<GBP, UnitLength>(numerator: 1, denominator: 1, per: .meters))
        // 1e19 kilometers = 1e22 meters — overflows Int64
        let huge = Measurement(value: 1e19, unit: UnitLength.kilometers)
        #expect(rate.price(for: huge) == nil)
    }
}
#endif
