import Testing
import SwiftMoney

@Suite("UnitRate - cost(for:)")
struct UnitRate_CostTests {

    // MARK: - Basic cost calculation

    @Test("2_000_000 kWh × £0.000023/kWh = £46.00 (4600 minor units)")
    func twoMillionKWhAt23MicroPounds() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        let result = unitRate.cost(for: 2_000_000)
        #expect(result.amount == Money<GBP>(minorUnits: 4600))
    }

    @Test("1 kWh × £0.000023/kWh rounds to £0.00")
    func oneKWhRoundsToZero() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        let result = unitRate.cost(for: 1)
        #expect(result.amount == Money<GBP>(minorUnits: 0))
    }

    @Test("1_000 kWh × £0.000023/kWh → 2.3 → rounds to £0.02 (2 minor units)")
    func oneThousandKWhRoundsTo2() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        let result = unitRate.cost(for: 1_000)
        #expect(result.amount == Money<GBP>(minorUnits: 2))
    }

    // MARK: - Zero quantity

    @Test("Zero quantity produces zero amount")
    func zeroQuantity() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        let result = unitRate.cost(for: 0)
        #expect(result.amount == Money<GBP>.zero)
    }

    @Test("Zero quantity returns zero effectiveRate")
    func zeroQuantityEffectiveRate() throws {
        let rate = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let unitRate = UnitRate<GBP, String>(rate, per: "kWh")
        let result = unitRate.cost(for: 0)
        #expect(result.effectiveRate == .zero)
    }

    // MARK: - Negative quantity

    @Test("Negative quantity × positive rate → negative amount")
    func negativeQuantityPositiveRate() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        let result = unitRate.cost(for: -2_000_000)
        #expect(result.amount == Money<GBP>(minorUnits: -4600))
    }

    // MARK: - Negative rate (feed-in)

    @Test("Positive quantity × negative rate → negative amount (feed-in credit)")
    func positiveQuantityNegativeRate() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: -23, denominator: 1_000_000, per: "kWh"))
        let result = unitRate.cost(for: 2_000_000)
        #expect(result.amount == Money<GBP>(minorUnits: -4600))
    }

    // MARK: - Rounding rule

    @Test("Rounding .down: 1_000 kWh × £0.000023/kWh → 2.3 → £0.02")
    func roundingDown() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        let result = unitRate.cost(for: 1_000, rounding: .down)
        #expect(result.amount == Money<GBP>(minorUnits: 2))
    }

    @Test("Rounding .up: 1 kWh × £0.000023/kWh → 0.0023 → £0.01")
    func roundingUp() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        let result = unitRate.cost(for: 1, rounding: .up)
        #expect(result.amount == Money<GBP>(minorUnits: 1))
    }

    // MARK: - Effective rate

    @Test("Exact calculation: effectiveRate matches input rate scaled by minQ")
    func exactEffectiveRate() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        let result = unitRate.cost(for: 2_000_000)
        // 2_000_000 × 23 × 100 / 1_000_000 = 4600 exactly
        // effectiveRate = 4600 / 2_000_000 = 23/10000 (reduced)
        let expectedRate = try #require(Rate(numerator: 23, denominator: 10_000))
        #expect(result.effectiveRate == expectedRate)
    }

    // MARK: - Different minimalQuantisation

    @Test("JPY (minQ=1): 1000 units × Rate(1,100) = 10 minor units")
    func jpyMinQ1() throws {
        let unitRate = try #require(UnitRate<JPY, String>(numerator: 1, denominator: 100, per: "item"))
        let result = unitRate.cost(for: 1000)
        #expect(result.amount == Money<JPY>(minorUnits: 10))
    }

    // MARK: - Zero rate

    @Test("Zero rate × any quantity = zero")
    func zeroRate() throws {
        let unitRate = try #require(UnitRate<GBP, String>(numerator: 0, denominator: 1, per: "kWh"))
        let result = unitRate.cost(for: 1_000_000)
        #expect(result.amount == Money<GBP>.zero)
    }
}
