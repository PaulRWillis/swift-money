import POCMoney
import Testing

// A currency defined entirely outside the library, proving no library change is needed to add one.
// This is the guarantee `CurrencyType` exists to provide, so it is a kept test rather than a scratch.
private enum LoyaltyPoints: CurrencyType {
    static let currency = Currency(code: "LTY", minimalQuantization: 1)
}

@Suite("Currency Tests")
struct CurrencyTests {

    // MARK: - The value

    @Test("A currency carries its code and quantization")
    func carriesCodeAndQuantization() {
        let currency = Currency(code: "GBP", minimalQuantization: 100)

        #expect(currency.code == "GBP")
        #expect(currency.minimalQuantization == 100)
    }

    @Test("Currencies with the same code and quantization are equal")
    func equality() {
        #expect(
            Currency(code: "GBP", minimalQuantization: 100)
                == Currency(code: "GBP", minimalQuantization: 100)
        )
    }

    @Test("Currencies differing in code are not equal")
    func differingCodesAreNotEqual() {
        #expect(
            Currency(code: "GBP", minimalQuantization: 100)
                != Currency(code: "EUR", minimalQuantization: 100)
        )
    }

    @Test("Currencies differing in quantization are not equal")
    func differingQuantizationsAreNotEqual() {
        #expect(
            Currency(code: "GBP", minimalQuantization: 100)
                != Currency(code: "GBP", minimalQuantization: 1)
        )
    }

    @Test("Equal currencies hash the same")
    func hashing() {
        let currencies: Set<Currency> = [
            Currency(code: "GBP", minimalQuantization: 100),
            Currency(code: "GBP", minimalQuantization: 100),
            Currency(code: "EUR", minimalQuantization: 100),
        ]

        #expect(currencies.count == 2)
    }

    @Test("A currency code is matched case-insensitively, so case does not split a currency")
    func codeCaseDoesNotSplitACurrency() {
        #expect(
            Currency(code: "gbp", minimalQuantization: 100)
                == Currency(code: "GBP", minimalQuantization: 100)
        )
    }

    // MARK: - The library's currencies

    @Test("The library's currencies expose the expected values")
    func libraryCurrencies() {
        #expect(Currencies.GBP.currency == Currency(code: "GBP", minimalQuantization: 100))
        #expect(Currencies.EUR.currency == Currency(code: "EUR", minimalQuantization: 100))
    }

    @Test("Named constants match their currency types")
    func namedConstants() {
        #expect(Currency.gbp == Currencies.GBP.currency)
        #expect(Currency.eur == Currencies.EUR.currency)
    }

    // MARK: - MoneyOf exposes its currency

    @Test("A typed amount reports the currency from its type parameter")
    func typedAmountReportsItsCurrency() {
        #expect(GBP(4_99).currency == .gbp)
        #expect(EUR(4_99).currency == .eur)
    }

    @Test("The currency is a property of the type, so every amount reports the same one")
    func currencyIsTheSameForEveryAmount() {
        #expect(GBP(0).currency == GBP(999_99).currency)
        #expect(GBP.min.currency == GBP.max.currency)
    }

    @Test("A typed amount reaches its quantization through its currency")
    func typedAmountReachesItsQuantization() {
        #expect(GBP(1).currency.minimalQuantization == 100)
    }

    // MARK: - Caller-defined currencies

    @Test("A currency defined outside the library works with MoneyOf")
    func callerDefinedCurrency() {
        typealias Points = MoneyOf<LoyaltyPoints>

        let earned = Points(250)
        let spent = Points(100)

        #expect(earned - spent == Points(150))
        #expect(earned.currency.code == "LTY")
        #expect(earned.currency.minimalQuantization == 1)
    }

    @Test("A caller-defined currency is distinct from the library's")
    func callerDefinedCurrencyIsDistinct() {
        #expect(LoyaltyPoints.currency != .gbp)
        #expect(LoyaltyPoints.currency.code == "LTY")
        #expect(LoyaltyPoints.currency.minimalQuantization == 1)
    }
}
