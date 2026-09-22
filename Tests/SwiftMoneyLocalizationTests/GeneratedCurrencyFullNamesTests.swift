import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// The names come from CLDR through the generator, and are read back out of the packed tables. These pin
// what it wrote for cases that differ in kind: a currency with two forms, one with a single form, and
// one CLDR does not name at all.
@Suite("Generated Currency Full Names Tests")
struct GeneratedCurrencyFullNamesTests {

    static func name(_ code: CurrencyCode, in locale: LocaleIdentifier, for category: PluralCategory) throws -> String {
        let names = try #require(MoneyLocalization.fullName(of: code, locale: locale))
        return names.name(for: category)
    }

    @Test("English names a currency one way for one and another for the rest")
    func englishNamesBothForms() throws {
        #expect(try Self.name("GBP", in: "en", for: .one) == "British pound")
        #expect(try Self.name("GBP", in: "en", for: .other) == "British pounds")
    }

    @Test("A currency with one name in a locale uses it for every category")
    func singleFormCoversEveryCategory() throws {
        #expect(try Self.name("USD", in: "de", for: .one) == "US-Dollar")
        #expect(try Self.name("USD", in: "de", for: .other) == "US-Dollar")
        #expect(try Self.name("JPY", in: "ja", for: .other) == "円")
    }

    // A handful of widely used locales, pinned by name. Most covered locales name these four too, but
    // a thin one names nothing at all, so this is a spot check rather than a rule over the whole set.
    @Test("A widely used locale names the currencies it is most likely to show", arguments: ["en", "en-GB", "de", "fr", "ja"])
    func commonLocalesNameTheCommonCurrencies(_ locale: LocaleIdentifier) {
        for code: CurrencyCode in ["GBP", "USD", "EUR", "JPY"] {
            #expect(MoneyLocalization.fullName(of: code, locale: locale) != nil, "\(locale.value) should name \(code)")
        }
    }

    // CLDR names 164 of the 165 currencies the library ships in English, and fewer in every other
    // locale, down to none at all in one that inherits from CLDR's root. A caller has to cope with a
    // currency having no name.
    @Test("A currency CLDR does not name is absent rather than made up")
    func unnamedCurrenciesAreAbsent() {
        let named = Currency.allISO4217.count { MoneyLocalization.fullName(of: $0.code, locale: "en") != nil }

        #expect(MoneyLocalization.fullName(of: "XAD", locale: "en") == nil)
        #expect(named < Currency.allISO4217.count)
    }

    @Test("A locale outside the tables names nothing")
    func uncoveredLocaleNamesNothing() {
        #expect(MoneyLocalization.fullName(of: "GBP", locale: "zz-ZZ") == nil)
    }
}
