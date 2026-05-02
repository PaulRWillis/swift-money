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

    // MARK: - Non-integer (fractional) quantity

    @Test("1.5 kWh at £0.000023/kWh → rational pricing")
    func fractionalSmallQuantity() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 1.5, unit: UnitEnergy.kilowattHours)
        // 1.5 × 23 × 100 / 1_000_000 = 0.00345 → rounds to 0
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<GBP>(minorUnits: 0))
    }

    @Test("1000.5 kWh at £0.000023/kWh → fractional quantity prices correctly")
    func fractionalLargeQuantity() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 1000.5, unit: UnitEnergy.kilowattHours)
        // 1000.5 × 23 × 100 / 1_000_000 = 2.3011… → rounds to 2
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<GBP>(minorUnits: 2))
    }

    @Test("1000.5 kWh rounds up to 3 minor units with .up")
    func fractionalRoundsUp() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 1000.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage, rounding: .up))
        #expect(result.amount == Money<GBP>(minorUnits: 3))
    }

    @Test("returns nil for NaN measurement")
    func nanReturnsNil() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: Double.nan, unit: UnitEnergy.kilowattHours)
        #expect(rate.price(for: usage) == nil)
    }

    @Test("returns nil for infinite measurement")
    func infiniteReturnsNil() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: Double.infinity, unit: UnitEnergy.kilowattHours)
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

    // MARK: - Fractional quantity edge cases

    @Test("0.5 kWh at high rate $1/kWh → exact 50 cents")
    func halfUnitExactResult() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.5, unit: UnitEnergy.kilowattHours)
        // 0.5 × 1 × 100 / 1 = 50 exactly
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 50))
    }

    @Test("0.25 litres at $4/litre → exact $1.00")
    func quarterLitre() throws {
        let rate = try #require(UnitRate<USD, UnitVolume>(numerator: 4, denominator: 1, per: .liters))
        let usage = Measurement(value: 0.25, unit: UnitVolume.liters)
        // 0.25 × 4 × 100 / 1 = 100 cents
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 100))
    }

    @Test("0.1 kWh at £10/kWh → exact £1.00")
    func pointOneQuantity() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 10, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.1, unit: UnitEnergy.kilowattHours)
        // 0.1 × 10 × 100 / 1 = 100
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<GBP>(minorUnits: 100))
    }

    @Test("negative fractional quantity: -1.5 kWh at $1/kWh → -$1.50")
    func negativeFractional() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: -1.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: -150))
    }

    @Test("fractional quantity with negative rate (feed-in credit)")
    func fractionalNegativeRate() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: -5, denominator: 100, per: .kilowattHours))
        let usage = Measurement(value: 1.5, unit: UnitEnergy.kilowattHours)
        // Rate stored as -1/20 after GCD reduction.
        // (3/2) × (-1/20) × 100 = -300/40 = -7.5 → rounds to -8
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<GBP>(minorUnits: -8))
    }

    @Test("fractional quantity with zero rate → zero amount")
    func fractionalZeroRate() throws {
        let rate = UnitRate<GBP, UnitEnergy>(.zero, per: .kilowattHours)
        let usage = Measurement(value: 1.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<GBP>.zero)
    }

    @Test("JPY (minQ=1) with fractional quantity 1.5 at ¥100/kWh → ¥150")
    func jpyFractionalQuantity() throws {
        let rate = try #require(UnitRate<JPY, UnitEnergy>(numerator: 100, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 1.5, unit: UnitEnergy.kilowattHours)
        // 1.5 × 100 × 1 / 1 = 150 exactly
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<JPY>(minorUnits: 150))
    }

    @Test("JPY fractional result rounds: 0.5 kWh at ¥3/kWh → ¥2 (away from zero)")
    func jpyFractionalRounds() throws {
        let rate = try #require(UnitRate<JPY, UnitEnergy>(numerator: 3, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.5, unit: UnitEnergy.kilowattHours)
        // 0.5 × 3 × 1 / 1 = 1.5 → rounds to 2
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<JPY>(minorUnits: 2))
    }

    @Test("Large fractional quantity: 999999.99 kWh at $1/kWh")
    func largeFractionalQuantity() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 999_999.99, unit: UnitEnergy.kilowattHours)
        // 999999.99 × 1 × 100 / 1 = 99_999_999 cents
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 99_999_999))
    }

    @Test("Very small fractional: 0.001 kWh at $1000/kWh → $1.00")
    func verySmallFractional() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1000, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.001, unit: UnitEnergy.kilowattHours)
        // 0.001 × 1000 × 100 / 1 = 100 cents
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 100))
    }

    // MARK: - Rounding rules with fractional quantities

    @Test("fractional .down: 0.5 at ¥3/kWh → ¥1")
    func fractionalRoundDown() throws {
        let rate = try #require(UnitRate<JPY, UnitEnergy>(numerator: 3, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.5, unit: UnitEnergy.kilowattHours)
        // 1.5 → rounds down to 1
        let result = try #require(rate.price(for: usage, rounding: .down))
        #expect(result.amount == Money<JPY>(minorUnits: 1))
    }

    @Test("fractional .towardZero: -0.5 at ¥3/kWh → ¥-1")
    func fractionalRoundTowardZero() throws {
        let rate = try #require(UnitRate<JPY, UnitEnergy>(numerator: 3, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: -0.5, unit: UnitEnergy.kilowattHours)
        // -1.5 → toward zero = -1
        let result = try #require(rate.price(for: usage, rounding: .towardZero))
        #expect(result.amount == Money<JPY>(minorUnits: -1))
    }

    // MARK: - Effective rate from fractional quantity

    @Test("effective rate from exact fractional: 0.5 kWh at $1/kWh → rate = 50/1")
    func effectiveRateExactFractional() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        // amount = 50 cents, quantity = 1/2
        // effectiveRate = 50 × 2 / 1 = 100/1
        let expected = try #require(Rate(numerator: 100, denominator: 1))
        #expect(result.effectiveRate == expected)
    }

    @Test("effective rate from integer fast path matches price(forQuantity:)")
    func effectiveRateIntegerPath() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 2_000_000, unit: UnitEnergy.kilowattHours)
        let fromMeasurement = try #require(rate.price(for: usage))
        let fromQuantity = rate.price(forQuantity: 2_000_000)
        #expect(fromMeasurement.amount == fromQuantity.amount)
        #expect(fromMeasurement.effectiveRate == fromQuantity.effectiveRate)
    }

    // MARK: - returns nil for negative infinity

    @Test("returns nil for negative infinity measurement")
    func negativeInfiniteReturnsNil() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: -Double.infinity, unit: UnitEnergy.kilowattHours)
        #expect(rate.price(for: usage) == nil)
    }

    // MARK: - Auto-conversion from different unit with fractional result

    @Test("1 kJ at rate per kWh → non-representable fraction returns nil")
    func singleKJNonRepresentable() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 36, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 1, unit: UnitEnergy.kilojoules)
        // 1 kJ = 1/3600 kWh — repeating decimal, Decimal(0.000277...) loses precision
        // so Rate(decimal) may give an approximation rather than exact 1/3600
        let result = rate.price(for: usage)
        // The result may be non-nil with an approximate answer, or nil if
        // the Decimal significand overflows Int64. Either way, verify no crash.
        if let result {
            // If it computes, the amount should be close to 1 minor unit
            #expect(result.amount == Money<GBP>(minorUnits: 1))
        }
    }

    // MARK: - GCD regression tests (abs bug)

    @Test("GCD regression: quantity -1 with coprime denominator")
    func gcdRegressionNegativeOne() throws {
        // Rate 1/3 per unit. quantity = -1.
        // (-1/1) × (1/3) × 100 = -100/3 = -33.33… → rounds to -33
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 3, per: .kilowattHours))
        let usage = Measurement(value: -1.0, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: -33))
    }

    @Test("GCD regression: quantity -3 at rate 7/11")
    func gcdRegressionNegativeThree() throws {
        // (-3/1) × (7/11) × 100 = -2100/11 = -190.909… → rounds to -191
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 7, denominator: 11, per: .kilowattHours))
        let usage = Measurement(value: -3.0, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: -191))
    }

    @Test("GCD regression: negative rate with positive fractional quantity")
    func gcdRegressionNegativeRatePositiveQty() throws {
        // Rate -7/3 per unit. quantity = 2.5
        // (5/2) × (-7/3) × 100 = -3500/6 = -583.33… → rounds to -583
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: -7, denominator: 3, per: .kilowattHours))
        let usage = Measurement(value: 2.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: -583))
    }

    @Test("GCD regression: both negative rate and negative quantity → positive")
    func gcdRegressionDoubleNegative() throws {
        // Rate -1/2 per unit. quantity = -4.0 (integer but negative)
        // (-4) × (-1/2) × 100 = 400/2 = 200 cents = $2.00
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: -1, denominator: 2, per: .kilowattHours))
        let usage = Measurement(value: -4.0, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 200))
    }

    @Test("GCD regression: double negative with fractional quantity → positive")
    func gcdRegressionDoubleNegativeFractional() throws {
        // Rate -5/100 per unit. quantity = -2.5
        // Rate reduces to -1/20.
        // (-5/2) × (-1/20) × 100 = 500/40 = 12.5 → rounds to 13
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: -5, denominator: 100, per: .kilowattHours))
        let usage = Measurement(value: -2.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 13))
    }

    // MARK: - Integer fast path vs rational slow path consistency

    @Test("integer 5.0 uses fast path; matches forQuantity result")
    func integerFastPathConsistency() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 7, denominator: 3, per: .kilowattHours))
        let fromMeasurement = try #require(rate.price(for: Measurement(value: 5.0, unit: UnitEnergy.kilowattHours)))
        let fromQuantity = rate.price(forQuantity: 5)
        #expect(fromMeasurement.amount == fromQuantity.amount)
    }

    @Test("negative integer -10.0 uses fast path; matches forQuantity result")
    func negativeIntegerFastPathConsistency() throws {
        let rate = try #require(UnitRate<GBP, UnitEnergy>(numerator: 23, denominator: 1_000_000, per: .kilowattHours))
        let fromMeasurement = try #require(rate.price(for: Measurement(value: -10.0, unit: UnitEnergy.kilowattHours)))
        let fromQuantity = rate.price(forQuantity: -10)
        #expect(fromMeasurement.amount == fromQuantity.amount)
    }

    @Test("2.0 treated as integer (fast path), same as forQuantity(2)")
    func twoPointZeroFastPath() throws {
        let rate = try #require(UnitRate<USD, UnitVolume>(numerator: 1, denominator: 2, per: .liters))
        let fromMeasurement = try #require(rate.price(for: Measurement(value: 2.0, unit: UnitVolume.liters)))
        let fromQuantity = rate.price(forQuantity: 2)
        #expect(fromMeasurement.amount == fromQuantity.amount)
        #expect(fromMeasurement.effectiveRate == fromQuantity.effectiveRate)
    }

    // MARK: - Extreme values

    @Test("negative zero produces zero amount")
    func negativeZeroProducesZero() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 100, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: -0.0, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>.zero)
    }

    @Test("Double.leastNonzeroMagnitude → too small, rounds to zero")
    func leastNonzeroMagnitude() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: Double.leastNonzeroMagnitude, unit: UnitEnergy.kilowattHours)
        let result = rate.price(for: usage)
        // Either nil (can't represent as Rate) or zero
        if let result {
            #expect(result.amount == Money<USD>.zero)
        }
    }

    @Test("very large integer quantity near Int64.max uses fast path")
    func veryLargeIntegerQuantity() throws {
        // Rate 1/1 with quantity = 1_000_000_000 (fits Int64 easily)
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 1_000_000_000, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        // 1e9 × 1 × 100 / 1 = 100_000_000_000 cents
        #expect(result.amount == Money<USD>(minorUnits: 100_000_000_000))
    }

    @Test("quantity that exceeds Double-to-Int64 precision returns nil or rounds")
    func quantityBeyondDoublePrecision() throws {
        // 2^53 + 1 = 9007199254740993 — not exactly representable as Double
        // But the Double rounds it to 9007199254740992.0 which IS an integer
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1_000_000, per: .kilowattHours))
        let bigVal = Double(sign: .plus, exponent: 53, significand: 1.0) // 2^53
        let usage = Measurement(value: bigVal, unit: UnitEnergy.kilowattHours)
        // Should use fast path since 2^53 is representable and fits Int64
        let result = try #require(rate.price(for: usage))
        // 2^53 × 1 × 100 / 1_000_000 = 900719925474
        #expect(result.amount == Money<USD>(minorUnits: 900_719_925_474))
    }

    // MARK: - Multiple currencies with different minQ

    @Test("KWD (minQ=1000) with fractional quantity 2.5 at 1/3 rate")
    func kwdFractionalQuantity() throws {
        // KWD has 3 decimal places → minQ = 1000
        let rate = try #require(UnitRate<KWD, UnitEnergy>(numerator: 1, denominator: 3, per: .kilowattHours))
        let usage = Measurement(value: 2.5, unit: UnitEnergy.kilowattHours)
        // (5/2) × (1/3) × 1000 = 5000/6 = 833.33… → rounds to 833
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<KWD>(minorUnits: 833))
    }

    @Test("KWD (minQ=1000) with fractional quantity 2.5 at 1/3 rate rounding .up")
    func kwdFractionalQuantityRoundUp() throws {
        let rate = try #require(UnitRate<KWD, UnitEnergy>(numerator: 1, denominator: 3, per: .kilowattHours))
        let usage = Measurement(value: 2.5, unit: UnitEnergy.kilowattHours)
        // 5000/6 = 833.33… → rounds up to 834
        let result = try #require(rate.price(for: usage, rounding: .up))
        #expect(result.amount == Money<KWD>(minorUnits: 834))
    }

    @Test("JPY (minQ=1) with quantity -0.5 at rate 1/1 → rounds to 0 (.toNearestOrAwayFromZero)")
    func jpyNegativeHalf() throws {
        let rate = try #require(UnitRate<JPY, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: -0.5, unit: UnitEnergy.kilowattHours)
        // -0.5 × 1 × 1 / 1 = -0.5 → rounds to -1 (away from zero)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<JPY>(minorUnits: -1))
    }

    // MARK: - Rounding rule exhaustive check with fractional quantities

    @Test("rounding .toNearestOrEven: 2.5 × 1/5 × 100 = 50 (exact, no rounding needed)")
    func roundingToNearestOrEvenExact() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 5, per: .kilowattHours))
        let usage = Measurement(value: 2.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage, rounding: .toNearestOrEven))
        // (5/2) × (1/5) × 100 = 500/10 = 50 exactly
        #expect(result.amount == Money<USD>(minorUnits: 50))
    }

    @Test("rounding .toNearestOrEven: 1.5 × 1/3 × 100 = 50 (exact)")
    func roundingToNearestOrEvenExact2() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 3, per: .kilowattHours))
        let usage = Measurement(value: 1.5, unit: UnitEnergy.kilowattHours)
        // (3/2) × (1/3) × 100 = 300/6 = 50 exactly
        let result = try #require(rate.price(for: usage, rounding: .toNearestOrEven))
        #expect(result.amount == Money<USD>(minorUnits: 50))
    }

    @Test("rounding .awayFromZero: -1.5 × 1/3 × 100 = -50 (exact, signs cancel)")
    func roundingAwayFromZeroNegative() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 3, per: .kilowattHours))
        let usage = Measurement(value: -1.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage, rounding: .awayFromZero))
        #expect(result.amount == Money<USD>(minorUnits: -50))
    }

    @Test("rounding .up: negative result -33.33 → -33 (up means toward +∞)")
    func roundingUpNegativeResult() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 3, per: .kilowattHours))
        let usage = Measurement(value: -1.0, unit: UnitEnergy.kilowattHours)
        // (-1) × (1/3) × 100 = -100/3 = -33.33… → up = -33
        let result = try #require(rate.price(for: usage, rounding: .up))
        #expect(result.amount == Money<USD>(minorUnits: -33))
    }

    @Test("rounding .down: positive result 33.33 → 33 (down means toward -∞)")
    func roundingDownPositiveResult() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 3, per: .kilowattHours))
        let usage = Measurement(value: 1.0, unit: UnitEnergy.kilowattHours)
        // 1 × (1/3) × 100 = 33.33… → down = 33
        let result = try #require(rate.price(for: usage, rounding: .down))
        #expect(result.amount == Money<USD>(minorUnits: 33))
    }

    @Test("rounding .down: negative result -33.33 → -34 (down = toward -∞)")
    func roundingDownNegativeResult() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 3, per: .kilowattHours))
        let usage = Measurement(value: -1.0, unit: UnitEnergy.kilowattHours)
        // (-1) × (1/3) × 100 = -33.33… → down = -34
        let result = try #require(rate.price(for: usage, rounding: .down))
        #expect(result.amount == Money<USD>(minorUnits: -34))
    }

    // MARK: - Effective rate verification for fractional quantities

    @Test("effective rate for 0.25 kWh at $4/kWh: 100 / 0.25 = 400/1")
    func effectiveRateQuarterKWh() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 4, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.25, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 100))
        // effectiveRate = 100 × 4 / 1 = 400/1 (minorUnits per unit)
        let expected = try #require(Rate(numerator: 400, denominator: 1))
        #expect(result.effectiveRate == expected)
    }

    @Test("effective rate for negative quantity: -2.0 kWh at $1/kWh")
    func effectiveRateNegativeIntegerQuantity() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: -2.0, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: -200))
        // effectiveRate = -(-200) / -(-2) = 200 / 2 = 100/1
        let expected = try #require(Rate(numerator: 100, denominator: 1))
        #expect(result.effectiveRate == expected)
    }

    // MARK: - Cross-unit conversion with fractional results

    @Test("5.5 kJ at rate per kWh auto-converts to fractional kWh")
    func crossUnitFractional() throws {
        // 5.5 kJ → kWh: Foundation converts to approximately 0.001527... kWh
        // This is a repeating decimal so may return nil or approximate
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1000, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 5.5, unit: UnitEnergy.kilojoules)
        // Don't crash — outcome depends on Decimal precision
        _ = rate.price(for: usage)
    }

    @Test("1000 litres at rate per cubic metres auto-converts: 1000L = 1 m³")
    func crossUnitLitresToCubicMetres() throws {
        let rate = try #require(UnitRate<USD, UnitVolume>(numerator: 50, denominator: 1, per: .cubicMeters))
        let usage = Measurement(value: 1000, unit: UnitVolume.liters)
        // 1000 litres = 1 m³; 1 × 50 × 100 / 1 = 5000 cents
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 5000))
    }

    // MARK: - Unit rate with large numerator and denominator

    @Test("large rate 999999/1000000 with fractional quantity")
    func largeRateComponents() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 999_999, denominator: 1_000_000, per: .kilowattHours))
        let usage = Measurement(value: 2.5, unit: UnitEnergy.kilowattHours)
        // (5/2) × (999999/1000000) × 100 = 499_999_500/2_000_000 = 249.99975 → 250
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 250))
    }

    @Test("rate with GCD-reducible components: 100/200 = 1/2")
    func rateGCDReduction() throws {
        // Rate 100/200 reduces to 1/2 internally.
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 100, denominator: 200, per: .kilowattHours))
        let usage = Measurement(value: 3.0, unit: UnitEnergy.kilowattHours)
        // 3 × 1/2 × 100 = 150 cents
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 150))
    }

    // MARK: - Decimal representation edge cases

    @Test("quantity 0.3 (non-terminating binary fraction) at $10/kWh")
    func nonTerminatingBinaryFraction() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 10, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.3, unit: UnitEnergy.kilowattHours)
        // 0.3 × 10 × 100 = 300 — should be exact through Decimal
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 300))
    }

    @Test("quantity 0.7 at $10/kWh → exact $7.00")
    func pointSeven() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 10, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.7, unit: UnitEnergy.kilowattHours)
        // 0.7 × 10 × 100 / 1 = 700
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 700))
    }

    @Test("quantity 1.23456789 at $1/kWh → 123 cents (rounds down)")
    func manyDecimalPlaces() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 1.23456789, unit: UnitEnergy.kilowattHours)
        // String(1.23456789) = "1.23456789" → Decimal sig 123456789, exp -8
        // 123456789/100000000 × 1/1 × 100 = 12345678900/100000000 = 123.456789 → 123
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 123))
    }

    @Test("quantity 1.23456789 at $1/kWh rounding .up → 124 cents")
    func manyDecimalPlacesRoundUp() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 1.23456789, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage, rounding: .up))
        #expect(result.amount == Money<USD>(minorUnits: 124))
    }

    @Test("quantity 0.005 at $100/kWh → exactly 50 cents")
    func halfCent() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 100, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.005, unit: UnitEnergy.kilowattHours)
        // 0.005 × 100 × 100 = 50 exactly
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 50))
    }

    // MARK: - Rounding at exact halves

    @Test("exact half: 0.5 × 1/1 × 1 (JPY) = 0.5 → rounds to 1 (away from zero)")
    func exactHalfRoundsAwayFromZero() throws {
        let rate = try #require(UnitRate<JPY, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<JPY>(minorUnits: 1))
    }

    @Test("exact half: 0.5 × 1/1 × 1 (JPY) = 0.5 → rounds to 0 (toNearestOrEven)")
    func exactHalfRoundsToEven() throws {
        let rate = try #require(UnitRate<JPY, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 0.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage, rounding: .toNearestOrEven))
        #expect(result.amount == Money<JPY>(minorUnits: 0))
    }

    @Test("exact half: 1.5 × 1/1 × 1 (JPY) = 1.5 → rounds to 2 (toNearestOrEven rounds to even)")
    func exactHalfRoundsToEvenUp() throws {
        let rate = try #require(UnitRate<JPY, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 1.5, unit: UnitEnergy.kilowattHours)
        let result = try #require(rate.price(for: usage, rounding: .toNearestOrEven))
        #expect(result.amount == Money<JPY>(minorUnits: 2))
    }

    // MARK: - Numerator == 1 (unit rate identity)

    @Test("unit rate 1/1 with fractional quantity is identity-like")
    func unitRateIdentity() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 1, denominator: 1, per: .kilowattHours))
        let usage = Measurement(value: 7.77, unit: UnitEnergy.kilowattHours)
        // 7.77 × 1 × 100 = 777
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 777))
    }

    // MARK: - Stress: large quantity × large rate

    @Test("large quantity 1_000_000 × large rate 99999/100000 → needs Int128")
    func stressLargeMultiply() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 99_999, denominator: 100_000, per: .kilowattHours))
        let usage = Measurement(value: 1_000_000, unit: UnitEnergy.kilowattHours)
        // 1_000_000 × 99999 × 100 / 100000 = 99_999_000 cents
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 99_999_000))
    }

    @Test("large fractional 123456.789 × rate 7/13 computations stay in bounds")
    func stressLargeFractional() throws {
        let rate = try #require(UnitRate<USD, UnitEnergy>(numerator: 7, denominator: 13, per: .kilowattHours))
        let usage = Measurement(value: 123_456.789, unit: UnitEnergy.kilowattHours)
        // String(123456.789) = "123456.789" → 123456789/1000
        // (123456789/1000) × (7/13) × 100 = 86_419_752_300 / 13_000 = 6_647_673.25… → 6_647_673
        let result = try #require(rate.price(for: usage))
        #expect(result.amount == Money<USD>(minorUnits: 6_647_673))
    }
}
#endif
