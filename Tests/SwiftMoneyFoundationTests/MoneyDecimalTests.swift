import Foundation
import SwiftMoneyCore
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

        #expect(Decimal(majorUnitsOf: GBP(minorUnits: -4_99)) == expected)
        #expect(Decimal(majorUnitsOf: JPY(minorUnits: 499)) == 499)
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

    @Test("Every amount a currency can hold round-trips losslessly")
    func roundTripsTheFullRange() {
        #expect(GBP(majorUnits: Decimal(majorUnitsOf: GBP.min)) == GBP.min)
        #expect(GBP(majorUnits: Decimal(majorUnitsOf: GBP.max)) == GBP.max)
    }

    @Test("The widest products a currency can make stay inside Decimal")
    func roundTripsTheWidestProducts() {
        // Scale 10^18 is the finest a currency reaches, so its extremes are the widest products, the
        // ones nearest Decimal's 38-digit ceiling. Scale 10 pairs the extremes with a single
        // fractional place, a different width through the bridge.
        let finest = customCurrency(code: "FIN", unitScale: 1_000_000_000_000_000_000)
        let tenths = customCurrency(code: "TEN", unitScale: 10)

        for currency in [finest, tenths] {
            let greatest = Money(minorUnits: Int64.max, currency: currency)
            let least = Money(minorUnits: Int64.min, currency: currency)

            #expect(Money(majorUnits: Decimal(majorUnitsOf: greatest), currency: currency) == greatest)
            #expect(Money(majorUnits: Decimal(majorUnitsOf: least), currency: currency) == least)
        }
    }

    @Test("A decimal that constructs an amount reads back as the same value")
    func roundTripsADecimalValue() throws {
        let listed = try #require(Decimal(string: "4.990"))
        let amount = try #require(Money(majorUnits: listed, currency: .gbp))

        #expect(Decimal(majorUnitsOf: amount) == listed)
    }
}
