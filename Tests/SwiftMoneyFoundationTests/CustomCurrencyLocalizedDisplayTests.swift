import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import SwiftMoneyLocalization
import Testing

// Resolving a localized display for a locale and rendering with it. A literal-backed resource resolves
// to the same glyph in every locale; a string catalog would vary the glyph, which this seam supports.
// The locale still flows through to the number grammar, so the same glyph reads differently per locale.
@Suite("Custom Currency Localized Display Tests")
struct CustomCurrencyLocalizedDisplayTests {

    static func currency(_ code: CurrencyCode) -> Currency {
        guard let currency = Currency(code: code, unitScale: 100) else {
            preconditionFailure("\(code) must not be a currency the library ships at another scale")
        }
        return currency
    }

    @Test("A resolved display renders in the given locale's number grammar")
    func resolvesPerLocale() throws {
        let localized = CustomCurrencyLocalizedDisplay(symbol: "💎")
        let gem = Self.currency("GEM")
        let money = Money(minorUnits: 500_00, currency: gem)

        let enDisplay = localized.resolved(for: Locale(identifier: "en_US"))
        let en = try #require(
            MoneyLocalization.moneyFormat(for: gem, display: enDisplay, locale: "en_US", presentation: .standard)
        )
        #expect(en.format(money) == "💎500.00")

        let deDisplay = localized.resolved(for: Locale(identifier: "de_DE"))
        let de = try #require(
            MoneyLocalization.moneyFormat(for: gem, display: deDisplay, locale: "de_DE", presentation: .standard)
        )
        #expect(de.format(money) == "500,00\u{00A0}💎")
    }

    @Test("A resolved narrow symbol is used for the narrow presentation")
    func resolvesNarrowSymbol() throws {
        let localized = CustomCurrencyLocalizedDisplay(symbol: "US$", narrowSymbol: "$", narrowSpacing: .fixed(.none))
        let gem = Self.currency("GEM")
        let display = localized.resolved(for: Locale(identifier: "en_US"))

        let narrow = try #require(
            MoneyLocalization.moneyFormat(for: gem, display: display, locale: "en_US", presentation: .narrow)
        )
        #expect(narrow.format(Money(minorUnits: 500_00, currency: gem)) == "$500.00")
    }
}
