import Testing
import Foundation
import SwiftMoney

// MARK: - Mock provider

/// A test double for ``ExchangeRateProvider`` that returns rates from a
/// hard-coded dictionary keyed by currency-code strings.
///
/// Supply rates as `(fromMinorUnits, toMinorUnits)` pairs. If a pair is absent
/// the provider returns `nil`, simulating an unavailable rate.
private struct MockExchangeRateProvider: ExchangeRateProvider {

    /// `fromCode → toCode → (fromMinorUnits, toMinorUnits)`.
    let rates: [String: [String: (Int64, Int64)]]

    func rate<From: Currency, To: Currency>(
        from: From.Type,
        to: To.Type
    ) -> ExchangeRate<From, To>? {
        guard let pair = rates[String(From.code)]?[String(To.code)] else { return nil }
        return ExchangeRate(from: pair.0, to: pair.1)
    }
}

// MARK: - ExchangeRateProvider protocol tests

@Suite("ExchangeRateProvider")
struct ExchangeRateProviderTests {

    @Test("Mock provider returns configured rate")
    func mockProviderReturnsRate() {
        let provider = MockExchangeRateProvider(rates: [
            "GBP": ["USD": (100, 135)],
        ])
        let rate = provider.rate(from: GBP.self, to: USD.self)
        #expect(rate != nil)
        #expect(rate?.fromMinorUnits == 20)   // 100:135 reduces to 20:27
        #expect(rate?.toMinorUnits == 27)
    }

    @Test("Mock provider returns nil for absent pair")
    func mockProviderReturnsNilForAbsentPair() {
        let provider = MockExchangeRateProvider(rates: [:])
        #expect(provider.rate(from: GBP.self, to: USD.self) == nil)
    }

    @Test("Mock provider returns identity rate for same-currency pair")
    func mockProviderIdentityRate() {
        let provider = MockExchangeRateProvider(rates: [
            "GBP": ["GBP": (1, 1)],
        ])
        let rate = provider.rate(from: GBP.self, to: GBP.self)
        #expect(rate?.fromMinorUnits == 1)
        #expect(rate?.toMinorUnits == 1)
    }
}

// MARK: - MoneyBag.total(in:using:) tests

@Suite("MoneyBag - total(in:using:)")
struct MoneyBag_TotalTests {

    // Provider: GBP→GBP identity, EUR→GBP at 85/100, USD→GBP at 74/100
    private let provider = MockExchangeRateProvider(rates: [
        "GBP": ["GBP": (1, 1)],
        "EUR": ["GBP": (100, 85)],
        "USD": ["GBP": (100, 74)],
    ])

    // MARK: - Edge cases

    @Test("Empty bag returns .zero")
    func emptyBagReturnsZero() {
        let bag = MoneyBag()
        #expect(bag.total(in: GBP.self, using: provider) == .zero)
    }

    @Test("Bag with only target currency returns that amount unchanged")
    func singleTargetCurrency() {
        let bag = MoneyBag(Money<GBP>(minorUnits: 500))
        #expect(bag.total(in: GBP.self, using: provider) == Money<GBP>(minorUnits: 500))
    }

    // MARK: - Single conversion

    @Test("EUR→GBP: €10.00 (1000 minor) at 85/100 → 850 pence")
    func singleConversion() {
        let bag = MoneyBag(Money<EUR>(minorUnits: 1000))
        #expect(bag.total(in: GBP.self, using: provider) == Money<GBP>(minorUnits: 850))
    }

    // MARK: - Multiple currencies

    @Test("£5.00 + €10.00 at 85p/€ = £5.00 + £8.50 = £13.50")
    func multiCurrencySum() {
        var bag = MoneyBag()
        bag.add(Money<GBP>(minorUnits: 500))
        bag.add(Money<EUR>(minorUnits: 1000))
        #expect(bag.total(in: GBP.self, using: provider) == Money<GBP>(minorUnits: 1350))
    }

    @Test("£5.00 + €10.00 + $10.00 at 85p/€ and 74p/$ = 500 + 850 + 740 = 2090p")
    func threeCurrencySum() {
        var bag = MoneyBag()
        bag.add(Money<GBP>(minorUnits: 500))
        bag.add(Money<EUR>(minorUnits: 1000))
        bag.add(Money<USD>(minorUnits: 1000))
        #expect(bag.total(in: GBP.self, using: provider) == Money<GBP>(minorUnits: 2090))
    }

    // MARK: - Rounding propagation

    @Test("Rounding .down: 1 EUR cent (1 minor unit) at 85/100 = 0.85 → 0p with .down")
    func roundingDown() {
        let bag = MoneyBag(Money<EUR>(minorUnits: 1))
        let result = bag.total(in: GBP.self, using: provider, rounding: .down)
        #expect(result == Money<GBP>(minorUnits: 0))
    }

    @Test("Rounding .up: 1 EUR cent at 85/100 = 0.85 → 1p with .up")
    func roundingUp() {
        let bag = MoneyBag(Money<EUR>(minorUnits: 1))
        let result = bag.total(in: GBP.self, using: provider, rounding: .up)
        #expect(result == Money<GBP>(minorUnits: 1))
    }

    // MARK: - Negative amounts

    @Test("Negative EUR amount converts to negative GBP")
    func negativeAmount() {
        let bag = MoneyBag(Money<EUR>(minorUnits: -1000))
        #expect(bag.total(in: GBP.self, using: provider) == Money<GBP>(minorUnits: -850))
    }

    // MARK: - Missing rate → nil

    @Test("Returns nil when provider cannot supply a rate")
    func missingRateReturnsNil() {
        let emptyProvider = MockExchangeRateProvider(rates: [:])
        let bag = MoneyBag(Money<EUR>(minorUnits: 1000))
        #expect(bag.total(in: GBP.self, using: emptyProvider) == nil)
    }

    @Test("Returns nil when one currency in a multi-currency bag has no rate")
    func partiallyMissingRateReturnsNil() {
        // EUR→GBP present, USD→GBP absent
        let partialProvider = MockExchangeRateProvider(rates: [
            "GBP": ["GBP": (1, 1)],
            "EUR": ["GBP": (100, 85)],
        ])
        var bag = MoneyBag()
        bag.add(Money<GBP>(minorUnits: 500))
        bag.add(Money<EUR>(minorUnits: 1000))
        bag.add(Money<USD>(minorUnits: 1000))
        #expect(bag.total(in: GBP.self, using: partialProvider) == nil)
    }

    // MARK: - Codable-decoded bag (nil currency metatype)

    @Test("Returns nil when any AnyMoney.currency is nil (Codable-decoded entry)")
    func nilCurrencyMetatypeReturnsNil() throws {
        // Codable-decode a MoneyBag; AnyMoney.currency will be nil.
        let json = #"{"entries":[{"minorUnits":500,"currencyCode":"GBP","minimalQuantisation":100}]}"#
        let bag = try JSONDecoder().decode(MoneyBag.self, from: Data(json.utf8))
        // The GBP entry's .currency is nil because Codable doesn't know the type.
        #expect(bag.total(in: GBP.self, using: provider) == nil)
    }
}
