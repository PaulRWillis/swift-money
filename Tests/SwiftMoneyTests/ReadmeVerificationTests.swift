// Temporary file to verify README code examples compile.
// Delete after verification.

import SwiftMoney
import Foundation
import Testing

// === Custom currency from README ===
enum BTC: Currency {
    static let code: CurrencyCode = "BTC"
    static let minimalQuantisation: MinimalQuantisation = 100_000_000
}

// === ExchangeRateProvider from README ===
private struct MyRates: ExchangeRateProvider {
    func rate<From: Currency, To: Currency>(
        from: From.Type, to: To.Type
    ) -> ExchangeRate<From, To>? {
        return nil
    }
}

@Suite("README — Compilation Verification")
struct ReadmeVerificationTests {

    @Test func introExample() {
        let price = Money<GBP>(minorUnits: 1250)
        let vatRate = Rate(numerator: 1, denominator: 5)!
        let vat = price.multiplied(by: vatRate, rounding: .toNearestOrAwayFromZero)
        #expect(vat.result == Money<GBP>(minorUnits: 250))
    }

    @Test func creatingValues() {
        let a = Money<GBP>(minorUnits: 125)
        let b: Money<GBP> = 500
        let c = Money<GBP>.zero
        let d = Money<GBP>.nan
        #expect(d.isNaN)
        _ = (a, b, c)
    }

    @Test func arithmetic() {
        let price = Money<GBP>(minorUnits: 1000)
        let tax   = Money<GBP>(minorUnits: 200)
        #expect(price + tax == Money<GBP>(minorUnits: 1200))
        #expect(price - tax == Money<GBP>(minorUnits: 800))

        let quantity: Int64 = 3
        #expect(price * quantity == Money<GBP>(minorUnits: 3000))

        var total = price
        total += tax
        #expect(total == Money<GBP>(minorUnits: 1200))
        total -= tax
        #expect(total == Money<GBP>(minorUnits: 1000))
        #expect(-price == Money<GBP>(minorUnits: -1000))
    }

    @Test func distribution() {
        let amount = Money<GBP>(minorUnits: 1000)
        switch amount.distributed(into: 3) {
        case .exact:
            Issue.record("Expected uneven distribution")
        case let .uneven(larger, largerCount, smaller, smallerCount):
            #expect(larger == Money<GBP>(minorUnits: 334))
            #expect(largerCount == 1)
            #expect(smaller == Money<GBP>(minorUnits: 333))
            #expect(smallerCount == 2)
        }
    }

    @Test func fractionalMultiplication() {
        let price = Money<GBP>(minorUnits: 1000)
        let vatRate = Rate(numerator: 1, denominator: 5)!
        let vat = price.multiplied(by: vatRate, rounding: .toNearestOrAwayFromZero)
        #expect(vat.result == Money<GBP>(minorUnits: 200))
    }

    @Test func exchangeRates() {
        let rate = ExchangeRate<GBP, USD>(from: 100, to: 135)!
        let gbp = Money<GBP>(minorUnits: 1000)
        let usd = rate.convert(gbp)
        #expect(usd == Money<USD>(minorUnits: 1350))
    }

    @Test func typeErasure() {
        let gbp = Money<GBP>(minorUnits: 500)
        let erased: AnyMoney = gbp.erased
        let recovered: Money<GBP>? = erased.asMoney(GBP.self)
        #expect(recovered == gbp)
    }

    @Test func moneyBag() {
        var bag = MoneyBag()
        bag.add(Money<GBP>(minorUnits: 500))
        bag.add(Money<EUR>(minorUnits: 1000))
        bag += Money<GBP>(minorUnits: 200)
        #expect(bag.balance(of: GBP.self) == Money<GBP>(minorUnits: 700))
        _ = bag.currencyCodes
        _ = bag.balances
    }

    @Test func formatting() {
        let price = Money<GBP>(minorUnits: 12550)
        let locale = Locale(identifier: "en_GB")
        _ = price.formatted()
        _ = price.formatted(.locale(locale))
        _ = price.formatted(.grouping(.never).locale(locale))
        _ = price.formatted(.precision(.fractionLength(0)).locale(locale))

        let erased = price.erased
        _ = erased.formatted()

        let bag = MoneyBag(price)
        _ = bag.formatted(locale: locale)
    }

    @Test func parsing() throws {
        let format = Money<GBP>.FormatStyle(locale: Locale(identifier: "en_GB"))
        let parsed = try Money<GBP>("£125.50", format: format)
        #expect(parsed == Money<GBP>(minorUnits: 12550))
        #expect(try format.parseStrategy.parse(format.format(parsed)) == parsed)
    }

    @Test func codableStrategies() {
        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        encoder.moneyEncodingStrategy = .majorUnits
        encoder.moneyEncodingStrategy = .string
        encoder.anyMoneyEncodingStrategy = .object(amount: .majorUnits)
        encoder.moneyBagEncodingStrategy = .dictionary(amount: .majorUnits)

        let decoder = JSONDecoder()
        decoder.anyMoneyDecodingStrategy = .object(
            amount: .majorUnits,
            resolver: CurrencyRegistry.isoStandard.asResolver()
        )
    }
}
