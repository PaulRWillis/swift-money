import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// The two axes this rendering unlocks: Burmese's accounting pattern moves the currency to the *other*
// side than its standard one (Axis A), and Khmer's letter-adjacent symbols (an ISO code, "F CFA")
// take a different side than its glyph symbols do (Axis B). Both used to keep the ICU fallback; now
// the engine renders them without it.
@Suite("Accounting currency side")
struct AccountingCurrencySideTests {

    static func currency(_ iso: String) -> Currency {
        guard let code = CurrencyCode(string: iso), let currency = Currency(iso: code) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return currency
    }

    // Burmese writes "1 234.56 €" under the automatic strategy (trailing) but "€1 234.56" under
    // accounting (leading) — its own accounting pattern moves the currency, which one arrangement per
    // locale could not say before this plan. (`no`/`nb`/`nn` are the plan's other headline examples,
    // but stay skipped for an unrelated, pre-existing reason; `uz`/`uz-Latn` looked clean too but the
    // ICU audit this plan's own §8 calls for caught a real gap mismatch between their standard and
    // accounting patterns that this engine cannot yet represent, so they stay refused rather than ship
    // wrong — see the report. `my` is the one side-move locale that is both clean and covered.)
    @Test("my renders a positive amount leading under .accounting and trailing under .automatic")
    func burmeseAccountingMovesLeading() throws {
        let eur = Self.currency("EUR")
        let format = try #require(
            MoneyLocalization.moneyFormat(for: eur, locale: "my"),
            "my should be a covered locale"
        )
        let amount = Money(minorUnits: 1_234_56, currency: eur)

        let automatic = format.format(amount)
        let accounting = format.format(amount, options: .init(sign: .accounting))

        #expect(automatic.hasSuffix("€"), "automatic: '\(automatic)' should trail with the symbol")
        #expect(accounting.hasPrefix("€"), "accounting: '\(accounting)' should lead with the symbol")
    }

    // Burmese's accounting pattern gives no negative subpattern of its own, so CLDR's own fallback —
    // a plain leading minus, not parentheses — applies, still ahead of the leading symbol.
    @Test("my marks a negative amount with a leading minus, still ahead of the leading form, under .accounting")
    func burmeseAccountingNegativeMinusSign() throws {
        let eur = Self.currency("EUR")
        let format = try #require(MoneyLocalization.moneyFormat(for: eur, locale: "my"))
        let negative = Money(minorUnits: -1_234_56, currency: eur)
        let accounting = format.format(negative, options: .init(sign: .accounting))

        #expect(accounting.hasPrefix("-€"), "'\(accounting)' should lead with a minus then the symbol")
    }

    // Khmer's XOF ("F CFA", letter-adjacent) takes the leading letter-form column; its EUR ("€", a
    // glyph) keeps the plain trailing column. Same locale, same sign strategy — the symbol decides.
    @Test("khq renders a letter-adjacent ISO code leading and a glyph symbol trailing")
    func khmerLetterFormPicksTheColumn() throws {
        let usd = Self.currency("USD")
        let eur = Self.currency("EUR")

        let isoFormat = try #require(
            MoneyLocalization.moneyFormat(for: usd, locale: "khq", presentation: .isoCode),
            "khq should be a covered locale"
        )
        let standardFormat = try #require(MoneyLocalization.moneyFormat(for: eur, locale: "khq"))

        let iso = isoFormat.format(Money(minorUnits: 1_00, currency: usd))
        let standard = standardFormat.format(Money(minorUnits: 1_00, currency: eur))

        #expect(iso.hasPrefix("USD"), "'\(iso)' should lead with the letter-adjacent code")
        #expect(standard.hasSuffix("€"), "'\(standard)' should trail with the glyph")
    }

    // en-GB has no accounting arrangement of its own and no letter-adjacent symbols among its common
    // currencies: this plan changes nothing observable for it.
    @Test("en-GB is unchanged: trailing sign only, no side flip under .accounting")
    func enGBUnchanged() throws {
        let gbp = Self.currency("GBP")
        let format = try #require(MoneyLocalization.moneyFormat(for: gbp, locale: "en-GB"))
        let amount = Money(minorUnits: 1_234_56, currency: gbp)
        let negative = Money(minorUnits: -1_234_56, currency: gbp)

        #expect(format.format(amount) == "£1,234.56")
        #expect(format.format(amount, options: .init(sign: .accounting)) == "£1,234.56")
        #expect(format.format(negative, options: .init(sign: .accounting)) == "(£1,234.56)")
    }

    // A custom currency's `.automatic` placement inherits the locale's own accounting arrangement
    // (§6.1): in `my`, that means leading under `.accounting` even though the currency itself is not
    // one CLDR ships — the fix this plan's own review found missing from the original draft.
    @Test("A custom currency with .automatic placement in my also renders leading under .accounting")
    func customCurrencyInheritsBurmeseAccountingSide() throws {
        let gem = CurrencyCode(string: "GEM").flatMap { Currency(code: $0, unitScale: 100) }
        let currency = try #require(gem)
        let display = CustomCurrencyDisplay(symbol: "GEM")
        let amount = Money(minorUnits: 1_234_56, currency: currency)

        let format = try #require(
            MoneyLocalization.moneyFormat(for: currency, display: display, locale: "my", presentation: .standard)
        )

        let automatic = format.format(amount)
        let accounting = format.format(amount, options: .init(sign: .accounting))

        #expect(automatic.hasSuffix("GEM"), "automatic: '\(automatic)' should trail with the symbol")
        #expect(accounting.hasPrefix("GEM"), "accounting: '\(accounting)' should lead with the symbol")
    }
}
