import SwiftMoneyCore
import Testing

private typealias Credits = MoneyOf<Millicredits>

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

@Suite("MoneyOf.Stride")
struct StrideTests {

    @Test("A zero amount is not a stride, typed or runtime")
    func zeroIsNil() {
        #expect(GBP.Stride(exactly: .zero) == nil)
        #expect(Money.Stride(exactly: pounds(0)) == nil)
    }

    @Test("Positive and negative amounts are strides that keep their amount")
    func nonZeroKeepsAmount() throws {
        #expect(try #require(GBP.Stride(exactly: GBP(minorUnits: 50))).amount == GBP(minorUnits: 50))
        #expect(try #require(GBP.Stride(exactly: GBP(minorUnits: -50))).amount == GBP(minorUnits: -50))
        #expect(try #require(Money.Stride(exactly: pounds(1))).amount == pounds(1))
        #expect(try #require(Money.Stride(exactly: pounds(-1))).amount == pounds(-1))
        #expect(try #require(GBP.Stride(exactly: .min)).amount == .min)
        #expect(try #require(GBP.Stride(exactly: .max)).amount == .max)
    }

    @Test("Equal strides are equal and hash equally; different amounts or currencies are not")
    func equality() throws {
        let fifty = try #require(Money.Stride(exactly: pounds(50)))
        let again = try #require(Money.Stride(exactly: pounds(50)))

        #expect(fifty == again)
        #expect(fifty.hashValue == again.hashValue)
        #expect(fifty != Money.Stride(exactly: pounds(-50)))
        #expect(fifty != Money.Stride(exactly: Money(minorUnits: 50, currency: .eur)))
    }

    @Test("A typed stride becomes a runtime one with the same amount and currency")
    func typedToRuntime() throws {
        let typed = try #require(JPY.Stride(exactly: JPY(minorUnits: -500)))

        #expect(Money.Stride(typed).amount == Money(minorUnits: -500, currency: .jpy))
    }

    @Test("A runtime stride in the matching currency becomes a typed one")
    func runtimeToTyped() throws {
        let runtime = try #require(Money.Stride(exactly: pounds(25)))

        #expect(try GBP.Stride(runtime) == GBP.Stride(exactly: GBP(minorUnits: 25)))
    }

    @Test("A runtime stride in another currency, or at another scale, throws a mismatch naming both")
    func runtimeToTypedMismatch() throws {
        let yen = try #require(Money.Stride(exactly: Money(minorUnits: 5, currency: .jpy)))
        let coarse = customCurrency(code: "MCR", unitScale: 1)
        let coarseCredits = try #require(Money.Stride(exactly: Money(minorUnits: 5, currency: coarse)))

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .jpy)) { try GBP.Stride(yen) }
        #expect(throws: MoneyError.currencyMismatch(lhs: Millicredits.currency, rhs: coarse)) {
            try Credits.Stride(coarseCredits)
        }
    }

    @Test("One minor unit is 1p, ¥1 and one millicredit; one major unit is £1, ¥1 and a credit")
    func typedSingleUnits() {
        #expect(GBP.Stride.minorUnit.amount == GBP(minorUnits: 1))
        #expect(GBP.Stride.majorUnit.amount == GBP(minorUnits: 1_00))
        #expect(JPY.Stride.minorUnit.amount == JPY(minorUnits: 1))
        #expect(JPY.Stride.majorUnit.amount == JPY(minorUnits: 1))
        #expect(Credits.Stride.minorUnit.amount == Credits(minorUnits: 1))
        #expect(Credits.Stride.majorUnit.amount == Credits(minorUnits: 1_000))
    }

    @Test("Runtime single units of a currency equal the typed ones", arguments: [Currency.gbp, .jpy, Millicredits.currency])
    func runtimeSingleUnits(_ currency: Currency) {
        let scale = Int64(currency.unitScale)

        #expect(Money.Stride.minorUnit(of: currency).amount == Money(minorUnits: 1, currency: currency))
        #expect(Money.Stride.majorUnit(of: currency).amount == Money(minorUnits: scale, currency: currency))
        #expect(Money.Stride(GBP.Stride.minorUnit) == .minorUnit(of: .gbp))
        #expect(Money.Stride(GBP.Stride.majorUnit) == .majorUnit(of: .gbp))
        #expect(Money.Stride(Credits.Stride.majorUnit) == .majorUnit(of: Millicredits.currency))
    }

    @Test("A unit of an amount is a unit of its currency", arguments: [Currency.gbp, .jpy, Millicredits.currency])
    func unitsOfAnAmount(_ currency: Currency) {
        let amount = Money(minorUnits: 123_456, currency: currency)

        #expect(Money.Stride.minorUnit(of: amount) == .minorUnit(of: currency))
        #expect(Money.Stride.majorUnit(of: amount) == .majorUnit(of: currency))
        #expect(Money.Stride.minorUnits(50, of: amount) == .minorUnits(50, of: currency))
        #expect(Money.Stride.majorUnits(-5, of: amount) == .majorUnits(-5, of: currency))
    }

    @Test("Multiples of a unit count minor units or major units, in either direction")
    func typedMultiples() {
        #expect(GBP.Stride.minorUnits(50).amount == GBP(minorUnits: 50))
        #expect(GBP.Stride.majorUnits(5).amount == GBP(minorUnits: 5_00))
        #expect(GBP.Stride.minorUnits(-50).amount == GBP(minorUnits: -50))
        #expect(GBP.Stride.majorUnits(-5).amount == GBP(minorUnits: -5_00))
        #expect(JPY.Stride.minorUnits(50).amount == JPY(minorUnits: 50))
        #expect(JPY.Stride.majorUnits(5).amount == JPY(minorUnits: 5))
        #expect(Credits.Stride.majorUnits(5).amount == Credits(minorUnits: 5_000))
    }

    @Test("Runtime multiples of a currency equal the typed ones")
    func runtimeMultiples() {
        #expect(Money.Stride.minorUnits(50, of: .gbp) == Money.Stride(GBP.Stride.minorUnits(50)))
        #expect(Money.Stride.majorUnits(5, of: .gbp) == Money.Stride(GBP.Stride.majorUnits(5)))
        #expect(Money.Stride.majorUnits(-5, of: .jpy) == Money.Stride(JPY.Stride.majorUnits(-5)))
        #expect(Money.Stride.majorUnits(5, of: Millicredits.currency) == Money.Stride(Credits.Stride.majorUnits(5)))
    }

    @Test("A count as large as a minor-unit amount can hold is a stride of that many minor units")
    func largestMinorUnitCounts() {
        #expect(GBP.Stride.minorUnits(9_223_372_036_854_775_807).amount == .max)
        #expect(GBP.Stride.minorUnits(-9_223_372_036_854_775_808).amount == .min)
        #expect(JPY.Stride.majorUnits(9_223_372_036_854_775_807).amount == .max)
    }

    #if EXIT_TESTS_SUPPORTED
    @Test("A zero unit count literal traps")
    func zeroUnitCountTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.Stride.UnitCount(0))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money.Stride.minorUnits(0, of: .gbp))
        }
    }

    @Test("A major-unit count literal too large for a typed currency traps")
    func overflowingTypedMajorUnitsTrap() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.Stride.majorUnits(9_223_372_036_854_775_807))
        }
    }
    #endif

    @Test("A major-unit count too large for a runtime currency is no stride, of a currency or an amount")
    func overflowingRuntimeMajorUnitsIsNil() {
        let fine = customCurrency(code: "XWE", unitScale: 1_000_000_000_000_000_000)

        #expect(Money.Stride.majorUnits(10, of: fine) == nil)
        #expect(Money.Stride.majorUnits(-10, of: Money(minorUnits: 1, currency: fine)) == nil)
        #expect(Money.Stride.majorUnits(-9_223_372_036_854_775_808, of: .gbp) == nil)
        #expect(Money.Stride.majorUnits(9, of: fine)?.amount == Money(minorUnits: 9_000_000_000_000_000_000, currency: fine))
    }
}
