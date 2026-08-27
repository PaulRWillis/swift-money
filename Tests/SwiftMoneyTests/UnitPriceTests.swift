import SwiftMoney
import Testing

@Suite("Unit Price Tests")
struct UnitPriceTests {

    // The headline example: £0.023 per kWh, billed for 1,000 kWh, settled once.
    @Test("A sub-minor-unit price totals a whole quantity and rounds once")
    func totalsAWholeQuantity() {
        let tariff = UnitPrice<Currencies.GBP, String>(GBP.Unrounded(majorUnits: "0.023"), per: "kWh")

        #expect(tariff.total(for: 1_000).rounded(.toNearestOrEven) == GBP(minorUnits: 23_00))
    }

    // 2.3 pence per unit × 350.5 units = 806.15 pence, settled once to 806.
    @Test("A fractional quantity totals and rounds once")
    func totalsAFractionalQuantity() throws {
        let price = UnitPrice<Currencies.GBP, String>(GBP.Unrounded(majorUnits: "0.023"), per: "kWh")
        let quantity = try #require(Rate(string: "350.5"))

        #expect(price.total(for: quantity).rounded(.toNearestOrEven) == GBP(minorUnits: 8_06))
    }

    // A price far below a minor unit stays exact through the multiply: 0.00000231 major units is
    // 0.000231 pence, and a million of them is 231 pence. Settling each unit first would give nothing.
    @Test("A price below a minor unit stays exact until settled")
    func subMinorUnitPriceStaysExact() {
        let rate = UnitPrice<Currencies.GBP, String>(GBP.Unrounded(majorUnits: "0.00000231"), per: "KB")

        #expect(rate.total(for: 1_000_000).rounded(.toNearestOrEven) == GBP(minorUnits: 2_31))
    }

    @Test("A whole quantity and the same quantity as a rate agree")
    func wholeAndRateQuantityAgree() throws {
        let price = UnitPrice<Currencies.GBP, String>(GBP.Unrounded(majorUnits: "0.023"), per: "kWh")
        let three = try #require(Rate(string: "3"))

        #expect(price.total(for: 3) == price.total(for: three))
    }

    @Test("The price reads back its amount and unit")
    func readsBackItsFields() {
        let perUnit = GBP.Unrounded(majorUnits: "0.023")
        let price = UnitPrice<Currencies.GBP, String>(perUnit, per: "kWh")

        #expect(price.amountPerUnit == perUnit)
        #expect(price.unit == "kWh")
    }

    @Test("Prices with the same amount and unit are equal, and differ otherwise")
    func equality() {
        let base = UnitPrice<Currencies.GBP, String>(GBP.Unrounded(majorUnits: "0.023"), per: "kWh")

        #expect(base == UnitPrice(GBP.Unrounded(majorUnits: "0.023"), per: "kWh"))
        #expect(base != UnitPrice(GBP.Unrounded(majorUnits: "0.024"), per: "kWh"))
        #expect(base != UnitPrice(GBP.Unrounded(majorUnits: "0.023"), per: "litre"))
    }

    // The unit is part of the type: a non-string label works just as well.
    @Test("A caller's own type can be the unit")
    func customUnitType() {
        enum Measure: Hashable, Sendable { case kilowattHour }

        let tariff = UnitPrice<Currencies.GBP, Measure>(GBP.Unrounded(majorUnits: "0.023"), per: .kilowattHour)

        #expect(tariff.unit == .kilowattHour)
        #expect(tariff.total(for: 1_000).rounded(.toNearestOrEven) == GBP(minorUnits: 23_00))
    }

    @Test("Totaling a quantity too large to represent traps")
    func totalTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            // A large per-unit price times the largest quantity exceeds the representable range.
            let price = UnitPrice<Currencies.GBP, String>(GBP(minorUnits: 1_000_000).unrounded, per: "kWh")
            blackHole(price.total(for: Int64.max))
        }
    }
}
