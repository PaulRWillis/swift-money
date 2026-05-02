#if canImport(Foundation)
import Foundation
import Testing
import SwiftMoney

@Suite("UnitRate+Decimal")
struct UnitRate_DecimalTests {

    @Test("init from Decimal 0.000023 per kWh")
    func decimalEnergyRate() throws {
        let unitRate = UnitRate<GBP, String>(Decimal(string: "0.000023")!, per: "kWh")
        let expected = try #require(UnitRate<GBP, String>(numerator: 23, denominator: 1_000_000, per: "kWh"))
        #expect(unitRate == expected)
    }

    @Test("init from Decimal 72.50 per barrel")
    func decimalOilPrice() throws {
        let unitRate = UnitRate<USD, String>(Decimal(string: "72.50")!, per: "barrel")
        let expected = try #require(UnitRate<USD, String>(numerator: 145, denominator: 2, per: "barrel"))
        #expect(unitRate == expected)
    }

    @Test("init from Decimal 0 returns zero rate")
    func decimalZero() {
        let unitRate = UnitRate<GBP, String>(Decimal(0), per: "kWh")
        #expect(unitRate?.rate == .zero)
    }

    @Test("init from Decimal NaN returns nil")
    func decimalNaN() {
        #expect(UnitRate<GBP, String>(Decimal.nan, per: "kWh") == nil)
    }

    @Test("init from negative Decimal -0.05 (feed-in credit)")
    func negativeDecimal() throws {
        let unitRate = UnitRate<GBP, String>(Decimal(string: "-0.05")!, per: "kWh")
        let expected = try #require(UnitRate<GBP, String>(numerator: -1, denominator: 20, per: "kWh"))
        #expect(unitRate == expected)
    }

    @Test("init from Decimal 1.0 (integer rate)")
    func decimalOne() throws {
        let unitRate = UnitRate<USD, String>(Decimal(1), per: "item")
        let expected = try #require(UnitRate<USD, String>(numerator: 1, denominator: 1, per: "item"))
        #expect(unitRate == expected)
    }
}
#endif
