import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Decimal Tests")
struct MoneyDecimalTests {

    @Test("A decimal number of major units becomes an amount, typed or runtime")
    func constructsFromMajorUnits() throws {
        let listed = try #require(Decimal(string: "4.99"))

        #expect(GBP(majorUnits: listed) == GBP(minorUnits: 4_99))
        #expect(GBP(majorUnits: -listed) == GBP(minorUnits: -4_99))
        #expect(Money(majorUnits: listed, currency: .gbp) == Money(minorUnits: 4_99, currency: .gbp))
    }

    @Test("An amount reads back as an exact decimal of major units")
    func readsBackAsDecimal() throws {
        let expected = try #require(Decimal(string: "-4.99"))

        #expect(Decimal(exactly: GBP(minorUnits: -4_99)) == expected)
        #expect(Decimal(exactly: JPY(minorUnits: 499)) == 499)
    }

    @Test("What the currency cannot hold exactly is refused, never rounded")
    func refusesWhatTheCurrencyCannotHold() throws {
        let tooFine = try #require(Decimal(string: "4.999"))
        let beyondStorage = try #require(Decimal(string: "10000000000000000000"))

        #expect(GBP(majorUnits: tooFine) == nil)
        #expect(GBP(majorUnits: beyondStorage) == nil)
        #expect(GBP(majorUnits: .nan) == nil)

        // Near `Decimal`'s own ceiling, multiplying by the scale overflows `Decimal` itself,
        // which is a refusal on a different branch from `beyondStorage` above.
        #expect(GBP(majorUnits: .greatestFiniteMagnitude) == nil)
        #expect(Money(majorUnits: .greatestFiniteMagnitude, currency: .gbp) == nil)
    }

    @Test("A currency that does not divide decimally converts in neither direction")
    func refusesANonDecimalCurrency() throws {
        // Both values are exact, 1.5 being 360 of 240 units and 120 units being 0.5,
        // so only the currency itself can be what is refused here.
        let gems = Currency(code: "GEM", unitScale: 240)
        let half = try #require(Decimal(string: "1.5"))

        #expect(Money(majorUnits: half, currency: gems) == nil)
        #expect(Decimal(exactly: Money(minorUnits: 120, currency: gems)) == nil)
    }

    @Test("Every amount a decimal currency can hold round-trips losslessly")
    func roundTripsTheFullRange() throws {
        let least = try #require(Decimal(exactly: GBP.min))
        let greatest = try #require(Decimal(exactly: GBP.max))

        #expect(GBP(majorUnits: least) == GBP.min)
        #expect(GBP(majorUnits: greatest) == GBP.max)
    }

    @Test("A decimal that constructs an amount reads back as the same value")
    func roundTripsADecimalValue() throws {
        let listed = try #require(Decimal(string: "4.990"))
        let amount = try #require(Money(majorUnits: listed, currency: .gbp))

        #expect(Decimal(exactly: amount) == listed)
    }
}
