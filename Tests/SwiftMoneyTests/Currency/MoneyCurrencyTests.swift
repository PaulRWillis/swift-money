import SwiftMoney
import Testing

@Suite("Money Currency Tests")
struct MoneyCurrencyTests {

    @Test("An amount reports the currency it was created with")
    func reportsItsCurrency() {
        #expect(Money(minorUnits: 4_99, currency: .gbp).currency == .gbp)
        #expect(Money(minorUnits: 4_99, currency: .eur).currency == .eur)
    }

    @Test("Amounts in a caller-defined currency combine with each other, but not with another")
    func callerDefinedCurrencyBehavesLikeAnyOther() throws {
        let points = Currency(code: "LTY", unitScale: 1)

        let earned = Money(minorUnits: 250, currency: points)
        let spent = Money(minorUnits: 100, currency: points)

        #expect(try earned - spent == Money(minorUnits: 150, currency: points))

        #expect(throws: MoneyError.currencyMismatch(lhs: points, rhs: .gbp)) {
            try earned + Money(minorUnits: 1, currency: .gbp)
        }
    }

    // Case used to split a currency in two, because the currency was a raw String compared exactly.
    // `CurrencyCode` normalizes, so these are now the same currency and the amounts combine.
    @Test("Case in a currency code no longer splits a currency")
    func caseDoesNotSplitACurrency() throws {
        let lower = Money(minorUnits: 5, currency: Currency(code: "gbp", unitScale: 100))
        let upper = Money(minorUnits: 7, currency: Currency(code: "GBP", unitScale: 100))

        #expect(try lower + upper == Money(minorUnits: 12, currency: .gbp))
    }

    // Two currencies sharing a code but disagreeing on scale are not the same currency, so
    // amounts in them must not combine: the alternative is silently adding 1/100ths to wholes.
    @Test("Currencies sharing a code but not a unit scale do not combine")
    func sameCodeDifferentUnitScaleDoesNotCombine() {
        let hundredths = Currency(code: "XYZ", unitScale: 100)
        let wholes = Currency(code: "XYZ", unitScale: 1)

        #expect(throws: MoneyError.currencyMismatch(lhs: hundredths, rhs: wholes)) {
            try Money(minorUnits: 5, currency: hundredths) + Money(minorUnits: 7, currency: wholes)
        }
    }

    @Test("The currency is part of an amount's identity")
    func currencyIsPartOfIdentity() {
        #expect(Money(minorUnits: 5, currency: .gbp) == Money(minorUnits: 5, currency: .gbp))
        #expect(Money(minorUnits: 5, currency: .gbp) != Money(minorUnits: 5, currency: .eur))

        let amounts: Set<Money> = [
            Money(minorUnits: 5, currency: .gbp),
            Money(minorUnits: 5, currency: .gbp),
            Money(minorUnits: 5, currency: .eur),
        ]

        #expect(amounts.count == 2)
    }
}
