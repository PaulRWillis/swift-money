import SwiftMoney
import Testing

// A currency defined entirely outside the library, proving no library change is needed to add one.
// This is the guarantee `CurrencyType` exists to provide, so it is a kept test rather than a scratch.
private enum LoyaltyPoints: CurrencyType {
    static let currency = Currency(code: "LTY", unitScale: 1)
}

@Suite("Currency Tests")
struct CurrencyTests {

    @Test("A currency carries its code and unit scale")
    func carriesCodeAndUnitScale() {
        let currency = Currency(code: "GBP", unitScale: 100)

        #expect(currency.code == "GBP")
        #expect(currency.unitScale == 100)
    }

    @Test("Currencies with the same code and unit scale are equal")
    func equality() {
        #expect(
            Currency(code: "GBP", unitScale: 100)
                == Currency(code: "GBP", unitScale: 100)
        )
    }

    @Test("Currencies differing in code are not equal")
    func differingCodesAreNotEqual() {
        #expect(
            Currency(code: "GBP", unitScale: 100)
                != Currency(code: "EUR", unitScale: 100)
        )
    }

    @Test("Currencies differing in unit scale are not equal")
    func differingUnitScalesAreNotEqual() {
        #expect(
            Currency(code: "GBP", unitScale: 100)
                != Currency(code: "GBP", unitScale: 1)
        )
    }

    @Test("Equal currencies hash the same")
    func hashing() {
        let currencies: Set<Currency> = [
            Currency(code: "GBP", unitScale: 100),
            Currency(code: "GBP", unitScale: 100),
            Currency(code: "EUR", unitScale: 100),
        ]

        #expect(currencies.count == 2)
    }

    @Test("A currency code is matched case-insensitively, so case does not split a currency")
    func codeCaseDoesNotSplitACurrency() {
        #expect(
            Currency(code: "gbp", unitScale: 100)
                == Currency(code: "GBP", unitScale: 100)
        )
    }

    @Test("The library's currencies expose the expected values")
    func libraryCurrencies() {
        #expect(Currencies.GBP.currency == Currency(code: "GBP", unitScale: 100))
        #expect(Currencies.EUR.currency == Currency(code: "EUR", unitScale: 100))
    }

    @Test("Named constants match their currency types")
    func namedConstants() {
        #expect(Currency.gbp == Currencies.GBP.currency)
        #expect(Currency.eur == Currencies.EUR.currency)
    }

    @Test("A typed amount reports the currency from its type parameter")
    func typedAmountReportsItsCurrency() {
        #expect(GBP(minorUnits: 4_99).currency == .gbp)
        #expect(EUR(minorUnits: 4_99).currency == .eur)
    }

    @Test("The currency is a property of the type, so every amount reports the same one")
    func currencyIsTheSameForEveryAmount() {
        #expect(GBP(minorUnits: 0).currency == GBP(minorUnits: 999_99).currency)
        #expect(GBP.min.currency == GBP.max.currency)
    }

    @Test("A typed amount reaches its unit scale through its currency")
    func typedAmountReachesItsUnitScale() {
        #expect(GBP(minorUnits: 1).currency.unitScale == 100)
    }

    @Test("A currency defined outside the library works with MoneyOf")
    func callerDefinedCurrency() {
        typealias Points = MoneyOf<LoyaltyPoints>

        let earned = Points(minorUnits: 250)
        let spent = Points(minorUnits: 100)

        #expect(earned - spent == Points(minorUnits: 150))
        #expect(earned.currency.code == "LTY")
        #expect(earned.currency.unitScale == 1)
    }

    @Test("A caller-defined currency is distinct from the library's")
    func callerDefinedCurrencyIsDistinct() {
        #expect(LoyaltyPoints.currency != .gbp)
        #expect(LoyaltyPoints.currency.code == "LTY")
        #expect(LoyaltyPoints.currency.unitScale == 1)
    }

    // The ouguiya divides into five khoums, which ISO 4217 cannot say: its exponent field holds a
    // power of ten, so it records 2 and footnotes the currency `divby5`. The table follows ISO,
    // because a scale of 5 would disagree with every payment system by a factor of twenty.
    @Test("A currency ISO cannot describe exactly follows ISO anyway")
    func divideByFiveCurrencyFollowsTheStandard() {
        #expect(Currency.mru.unitScale == 100)
        #expect(Currency.mga.unitScale == 100)
    }

    @Test("A currency without a name at the top level is still usable as a type")
    func currencyReachedThroughTheNamespace() {
        let paid = MoneyOf<Currencies.CHF>(minorUnits: 12_50)

        #expect(paid.currency == .chf)
        #expect(paid.currency.code == "CHF")
    }
}
