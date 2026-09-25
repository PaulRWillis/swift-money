import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Resolving a currency format for an explicit numbering system through the public entry point: an imposing
// system swaps digits and separators, a reuse system swaps digits only, the automatic path is unchanged, and
// a locale's own default resolves to the baked format.
@Suite("Numbering System Resolution Tests")
struct NumberingSystemResolutionTests {

    static func currency(_ iso: String) -> Currency {
        guard let code = CurrencyCode(string: iso), let currency = Currency(iso: code) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return currency
    }

    // A GBP amount formatted for `locale` in `system`, rendered so digits and separators show.
    static func rendered(
        _ minorUnits: Int64,
        locale: LocaleIdentifier,
        system: NumberingSystemSelection
    ) -> String? {
        MoneyLocalization.moneyFormat(for: currency("GBP"), locale: locale, numberingSystem: system)
            .map { $0.format(Money(minorUnits: minorUnits, currency: currency("GBP"))) }
    }

    @Test("automatic renders exactly as the plain entry point does")
    func automaticMatchesDefault() {
        #expect(Self.rendered(1_234_56, locale: "en-GB", system: .automatic) == "£1,234.56")
    }

    @Test("An imposing system swaps digits and separators")
    func imposingSwapsBoth() {
        // arab: Arabic-Indic digits, ٫ decimal, ٬ grouping.
        #expect(Self.rendered(1_234_56, locale: "en-GB", system: .explicit(.arabicIndic)) == "£١٬٢٣٤٫٥٦")
    }

    @Test("A reuse system swaps digits but keeps the locale's Latin separators")
    func reuseSwapsDigitsOnly() {
        // N'Ko digits with en-GB's own "," / "." separators.
        #expect(Self.rendered(1_234_56, locale: "en-GB", system: .explicit(.nko)) == "£߁,߂߃߄.߅߆")
    }

    @Test("Devanagari swaps digits, keeping Latin separators")
    func devanagariReuse() {
        #expect(Self.rendered(1_234_56, locale: "en-GB", system: .explicit(.devanagari)) == "£१,२३४.५६")
    }

    @Test("A locale's own default system resolves to the baked format")
    func ownDefaultIsBaked() throws {
        // bn defaults to beng, so bn@beng must equal bn with no system asked for.
        let baked = try #require(MoneyLocalization.moneyFormat(for: Self.currency("GBP"), locale: "bn"))
        let requested = try #require(
            MoneyLocalization.moneyFormat(
                for: Self.currency("GBP"), locale: "bn", numberingSystem: .explicit(.bengali)
            )
        )
        let amount = Money(minorUnits: 1_234_56, currency: Self.currency("GBP"))
        #expect(requested.format(amount) == baked.format(amount))
    }

    @Test("A reuse system on an imposing-default locale uses that locale's Latin separators")
    func reuseOnImposingDefaultLocale() throws {
        // ur-IN defaults to arabext (Arabic ٬/٫ separators), but its Latin form uses "," and ".".
        // Swapping to Latin digits must revert to those, not keep the imposed Arabic ones.
        let out = try #require(Self.rendered(1_234_56, locale: "ur-IN", system: .explicit(.latin)))
        #expect(out.contains("1,234.56"))
        #expect(!out.contains("٬"))
        #expect(!out.contains("٫"))
    }

    @Test("An unmodelled locale stays nil whatever the system")
    func uncoveredLocaleNil() {
        #expect(
            MoneyLocalization.moneyFormat(
                for: Self.currency("GBP"), locale: "zz", numberingSystem: .explicit(.arabicIndic)
            ) == nil
        )
    }
}
