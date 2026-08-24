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

    @Test("Every amount a currency can hold round-trips losslessly")
    func roundTripsTheFullRange() throws {
        let least = try #require(Decimal(exactly: GBP.min))
        let greatest = try #require(Decimal(exactly: GBP.max))

        #expect(GBP(majorUnits: least) == GBP.min)
        #expect(GBP(majorUnits: greatest) == GBP.max)
    }

    @Test("The widest products a currency can make stay inside Decimal")
    func roundTripsTheWidestProducts() throws {
        // Scale 2^18 makes the largest multiplier, 5^18, so its extremes are the 32-digit
        // products nearest Decimal's 38-digit ceiling. Scale 2 pairs the extremes with a
        // fractional half, whose products need twenty digits and so pass UInt64.
        let finest = Currency(code: "FIN", unitScale: 262_144)
        let halves = Currency(code: "HLV", unitScale: 2)

        for currency in [finest, halves] {
            let greatest = Money(minorUnits: Int64.max, currency: currency)
            let least = Money(minorUnits: Int64.min, currency: currency)

            let greatestDecimal = try #require(Decimal(exactly: greatest))
            let leastDecimal = try #require(Decimal(exactly: least))

            #expect(Money(majorUnits: greatestDecimal, currency: currency) == greatest)
            #expect(Money(majorUnits: leastDecimal, currency: currency) == least)
        }
    }

    @Test("A decimal that constructs an amount reads back as the same value")
    func roundTripsADecimalValue() throws {
        let listed = try #require(Decimal(string: "4.990"))
        let amount = try #require(Money(majorUnits: listed, currency: .gbp))

        #expect(Decimal(exactly: amount) == listed)
    }
}
