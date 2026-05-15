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

    @Test("Empty bag returns zero result")
    func emptyBagReturnsZero() {
        let result = MoneyBag().total(in: GBP.self, using: provider)
        #expect(result != nil)
        #expect(result?.total == .zero)
        #expect(result?.exactNumerator == 0)
        #expect(result?.exactDenominator == 1)
    }

    @Test("Bag with only target currency returns that amount unchanged")
    func singleTargetCurrency() {
        let bag = MoneyBag(Money<GBP>(minorUnits: 500))
        #expect(bag.total(in: GBP.self, using: provider)?.total == Money<GBP>(minorUnits: 500))
    }

    // MARK: - Single conversion

    @Test("EUR→GBP: €10.00 (1000 minor) at 85/100 → 850 pence")
    func singleConversion() {
        let bag = MoneyBag(Money<EUR>(minorUnits: 1000))
        #expect(bag.total(in: GBP.self, using: provider)?.total == Money<GBP>(minorUnits: 850))
    }

    // MARK: - Multiple currencies

    @Test("£5.00 + €10.00 at 85p/€ = £5.00 + £8.50 = £13.50")
    func multiCurrencySum() {
        var bag = MoneyBag()
        bag.add(Money<GBP>(minorUnits: 500))
        bag.add(Money<EUR>(minorUnits: 1000))
        #expect(bag.total(in: GBP.self, using: provider)?.total == Money<GBP>(minorUnits: 1350))
    }

    @Test("£5.00 + €10.00 + $10.00 at 85p/€ and 74p/$ = 500 + 850 + 740 = 2090p")
    func threeCurrencySum() {
        var bag = MoneyBag()
        bag.add(Money<GBP>(minorUnits: 500))
        bag.add(Money<EUR>(minorUnits: 1000))
        bag.add(Money<USD>(minorUnits: 1000))
        #expect(bag.total(in: GBP.self, using: provider)?.total == Money<GBP>(minorUnits: 2090))
    }

    // MARK: - Rounding propagation

    @Test("Rounding .down: 1 EUR cent (1 minor unit) at 85/100 = 0.85 → 0p with .down")
    func roundingDown() {
        let bag = MoneyBag(Money<EUR>(minorUnits: 1))
        let result = bag.total(in: GBP.self, using: provider, rounding: .down)
        #expect(result?.total == Money<GBP>(minorUnits: 0))
    }

    @Test("Rounding .up: 1 EUR cent at 85/100 = 0.85 → 1p with .up")
    func roundingUp() {
        let bag = MoneyBag(Money<EUR>(minorUnits: 1))
        let result = bag.total(in: GBP.self, using: provider, rounding: .up)
        #expect(result?.total == Money<GBP>(minorUnits: 1))
    }

    // MARK: - Negative amounts

    @Test("Negative EUR amount converts to negative GBP")
    func negativeAmount() {
        let bag = MoneyBag(Money<EUR>(minorUnits: -1000))
        #expect(bag.total(in: GBP.self, using: provider)?.total == Money<GBP>(minorUnits: -850))
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

    // MARK: - Single-rounding guarantee and exact fraction

    /// Worked example from the SwiftMoney design doc:
    ///
    /// 10.05 USD (1005 cents) + 200.00 GBP (20000 pence) + 503 JPY
    ///   USD→GBP at 1.0045 → ExchangeRate(from:10000, to:10045) → GCD=5 → 2000:2009
    ///   JPY→GBP at 1.1039 → ExchangeRate(from:100, to:11039)
    ///   GBP identity: 1:1
    ///
    /// Exact total = 30614277/400 = 76535.6925 pence
    /// Rounded (HALF_EVEN or HALF_UP, since 0.6925 > 0.5) = 76536p = £765.36
    @Test("Three-currency worked example: USD+GBP+JPY→GBP exact fraction")
    func threeWayWorkedExample() {
        let workedProvider = MockExchangeRateProvider(rates: [
            "GBP": ["GBP": (1, 1)],
            "USD": ["GBP": (10000, 10045)],   // 1.0045 GBP per USD (minor-unit pair)
            "JPY": ["GBP": (100, 11039)],     // 1.1039 GBP per JPY (minor-unit pair)
        ])
        var bag = MoneyBag()
        bag.add(Money<USD>(minorUnits: 1005))   // $10.05
        bag.add(Money<GBP>(minorUnits: 20000))  // £200.00
        bag.add(Money<JPY>(minorUnits: 503))    // ¥503

        let result = bag.total(in: GBP.self, using: workedProvider)
        #expect(result != nil)
        #expect(result?.total == Money<GBP>(minorUnits: 76536))  // £765.36
        #expect(result?.exactNumerator == 30614277)
        #expect(result?.exactDenominator == 400)
    }

    @Test("Single-rounding invariant: |residual| × 2 ≤ exactDenominator")
    func singleRoundingInvariant() {
        // Exact total = 30614277/400 = 76535.6925
        // residual = exactNumerator − total.minorUnits × exactDenominator
        //          = 30614277 − 76536 × 400 = 30614277 − 30614400 = −123
        // |−123| × 2 = 246 ≤ 400 ✓
        let workedProvider = MockExchangeRateProvider(rates: [
            "GBP": ["GBP": (1, 1)],
            "USD": ["GBP": (10000, 10045)],
            "JPY": ["GBP": (100, 11039)],
        ])
        var bag = MoneyBag()
        bag.add(Money<USD>(minorUnits: 1005))
        bag.add(Money<GBP>(minorUnits: 20000))
        bag.add(Money<JPY>(minorUnits: 503))

        guard let r = bag.total(in: GBP.self, using: workedProvider) else {
            Issue.record("total returned nil")
            return
        }
        let residual = r.exactNumerator - Int128(Int64(r.total.minorUnits)) * r.exactDenominator
        let absResidual = residual < 0 ? -residual : residual
        // Invariant: |residual| × 2 ≤ exactDenominator (single-rounding guarantee)
        #expect(absResidual * 2 <= r.exactDenominator)
        // Concrete check for this example:
        #expect(residual == -123)
    }

    @Test("HALF_EVEN rounds tie to even; HALF_UP rounds tie away from zero")
    func halfEvenVsHalfUp() {
        // 1 EUR cent at 50/100 = exactly 0.5p (exact tie).
        // Rate 50:100 → GCD=50 → 1:2. product=1*1=1, denominator=2, remainder=1.
        // Truncated quotient = 0 (even). Tie.
        //   HALF_EVEN: truncated (0) is already even → stay at 0
        //   HALF_UP:   round away from zero → +1 → 1
        let halfProvider = MockExchangeRateProvider(rates: [
            "EUR": ["GBP": (100, 50)],  // 50p per 100 EUR cents = 0.5p per cent
        ])
        let bag = MoneyBag(Money<EUR>(minorUnits: 1))
        let halfEvenResult = bag.total(in: GBP.self, using: halfProvider, rounding: .toNearestOrEven)
        let halfUpResult   = bag.total(in: GBP.self, using: halfProvider, rounding: .toNearestOrAwayFromZero)
        #expect(halfEvenResult?.total == Money<GBP>(minorUnits: 0))  // even (0) wins
        #expect(halfUpResult?.total   == Money<GBP>(minorUnits: 1))  // away from zero
    }
}

