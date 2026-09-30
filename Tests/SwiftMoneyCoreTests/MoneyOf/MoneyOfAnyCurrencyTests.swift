import SwiftMoneyCore
import Testing

private let convertedAmounts: [GBP] = samples(
    .typedMoney(minorUnitsIn: Int64.min ... Int64.max),
    seed: PropertySeed.amountConversion,
    edges: [.zero, .min, .max, GBP(minorUnits: -1)]
)

@Suite("MoneyOf typed and runtime conversions")
struct MoneyOfAnyCurrencyTests {

    @Test("A typed amount becomes a runtime one with the same amount and currency")
    func typedToRuntime() {
        let money = Money(GBP(minorUnits: 4_99))

        #expect(money == Money(minorUnits: 4_99, currency: .gbp))
        #expect(money.currency == .gbp)
        #expect(Money(JPY(minorUnits: 499)) == Money(minorUnits: 499, currency: .jpy))
    }

    @Test("A runtime amount in the matching currency becomes a typed one")
    func runtimeToTyped() throws {
        #expect(try GBP(Money(minorUnits: 4_99, currency: .gbp)) == GBP(minorUnits: 4_99))
        #expect(try JPY(Money(minorUnits: 499, currency: .jpy)) == JPY(minorUnits: 499))
    }

    @Test("A runtime amount in another currency throws a mismatch naming both")
    func runtimeToTypedMismatch() {
        let euros = Money(minorUnits: 10_00, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try GBP(euros)
        }
    }

    @Test("A runtime amount with the same code at another scale throws a mismatch")
    func runtimeToTypedScaleMismatch() throws {
        let coarse = customCurrency(code: "MCR", unitScale: 1)
        let money = Money(minorUnits: 7, currency: coarse)

        #expect(throws: MoneyError.currencyMismatch(lhs: Millicredits.currency, rhs: coarse)) {
            try MoneyOf<Millicredits>(money)
        }
        #expect(try MoneyOf<Millicredits>(Money(minorUnits: 7, currency: Millicredits.currency)) == MoneyOf<Millicredits>(minorUnits: 7))
    }

    @Test("A typed amount survives a round trip through a runtime one", arguments: convertedAmounts)
    func roundTrip(_ amount: GBP) throws {
        #expect(try GBP(Money(amount)) == amount)
    }
}
