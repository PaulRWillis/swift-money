import POCMoney
import Testing

@Suite("Money Currency Tests")
struct MoneyCurrencyTests {

    @Test("An amount reports the currency it was created with")
    func reportsItsCurrency() {
        #expect(Money(4_99, currency: .gbp).currency == .gbp)
        #expect(Money(4_99, currency: .eur).currency == .eur)
    }

    @Test("Amounts in a caller-defined currency combine with each other, but not with another")
    func callerDefinedCurrencyBehavesLikeAnyOther() {
        let points = Currency(code: "LTY", minimalQuantization: 1)

        let earned = Money(250, currency: points)
        let spent = Money(100, currency: points)

        #expect(earned - spent == Money(150, currency: points))
        #expect(earned + Money(1, currency: .gbp) == nil)
    }

    // Case used to split a currency in two, because the currency was a raw String compared exactly.
    // `CurrencyCode` normalizes, so these are now the same currency and the amounts combine.
    @Test("Case in a currency code no longer splits a currency")
    func caseDoesNotSplitACurrency() {
        let lower = Money(5, currency: Currency(code: "gbp", minimalQuantization: 100))
        let upper = Money(7, currency: Currency(code: "GBP", minimalQuantization: 100))

        #expect(lower + upper == Money(12, currency: .gbp))
    }

    // Two currencies sharing a code but disagreeing on quantization are not the same currency, so
    // amounts in them must not combine — the alternative is silently adding 1/100ths to wholes.
    @Test("Currencies sharing a code but not a quantization do not combine")
    func sameCodeDifferentQuantizationDoesNotCombine() {
        let hundredths = Money(5, currency: Currency(code: "XYZ", minimalQuantization: 100))
        let wholes = Money(7, currency: Currency(code: "XYZ", minimalQuantization: 1))

        #expect(hundredths + wholes == nil)
    }

    @Test("The currency is part of an amount's identity")
    func currencyIsPartOfIdentity() {
        #expect(Money(5, currency: .gbp) == Money(5, currency: .gbp))
        #expect(Money(5, currency: .gbp) != Money(5, currency: .eur))

        let amounts: Set<Money> = [
            Money(5, currency: .gbp),
            Money(5, currency: .gbp),
            Money(5, currency: .eur),
        ]

        #expect(amounts.count == 2)
    }
}
