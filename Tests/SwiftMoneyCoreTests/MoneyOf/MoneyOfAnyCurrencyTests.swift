import SwiftMoneyCore
import Testing

private let convertedAmounts: [GBP] = samples(
    .typedMoney(minorUnitsIn: Int64.min ... Int64.max),
    seed: PropertySeed.amountConversion,
    edges: [.zero, .min, .max, GBP(minorUnits: -1)]
)

private let edgeMinorUnits: [Int64] = [.min, -1, 0, 1, 4_99, .max]

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
    }

    @Test("A runtime amount at the custom currency's own scale becomes a typed one")
    func runtimeToTypedCustomScale() throws {
        let money = Money(minorUnits: 7, currency: Millicredits.currency)

        #expect(try MoneyOf<Millicredits>(money) == MoneyOf<Millicredits>(minorUnits: 7))
    }

    @Test("A typed amount survives a round trip through a runtime one", arguments: convertedAmounts)
    func roundTrip(_ amount: GBP) throws {
        #expect(try GBP(Money(amount)) == amount)
    }

    @Test("A runtime amount survives a round trip through a typed one", arguments: convertedAmounts)
    func reverseRoundTrip(_ amount: GBP) throws {
        let money = Money(amount)

        #expect(Money(try GBP(money)) == money)
    }

    @Test(
        "A yen amount converts to the same amount each way and survives a round trip",
        arguments: edgeMinorUnits
    )
    func yenRoundTrip(minorUnits: Int64) throws {
        let typed = JPY(minorUnits: minorUnits)
        let money = Money(minorUnits: minorUnits, currency: .jpy)

        #expect(Money(typed) == money)
        #expect(try JPY(money) == typed)
        #expect(try JPY(Money(typed)) == typed)
        #expect(Money(try JPY(money)) == money)
    }

    @Test(
        "A custom currency's amount converts to the same amount each way and survives a round trip",
        arguments: edgeMinorUnits
    )
    func customCurrencyRoundTrip(minorUnits: Int64) throws {
        let typed = MoneyOf<Millicredits>(minorUnits: minorUnits)
        let money = Money(minorUnits: minorUnits, currency: Millicredits.currency)

        #expect(Money(typed) == money)
        #expect(try MoneyOf<Millicredits>(money) == typed)
        #expect(try MoneyOf<Millicredits>(Money(typed)) == typed)
        #expect(Money(try MoneyOf<Millicredits>(money)) == money)
    }
}
