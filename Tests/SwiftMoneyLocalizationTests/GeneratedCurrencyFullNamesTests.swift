import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// The names come from CLDR through the generator. These pin what it wrote for cases that differ in
// kind: a currency with two forms, one with a single form, and one CLDR does not name at all.
@Suite("Generated Currency Full Names Tests")
struct GeneratedCurrencyFullNamesTests {

    static func name(_ code: CurrencyCode, in locale: String, for category: PluralCategory) throws -> String {
        let names = try #require(MoneyLocalization.currencyFullNames[locale]?[code])
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

    @Test("Every shipped locale names the currencies it is most likely to show", arguments: ["en", "en-GB", "de", "fr", "ja"])
    func everyLocaleNamesTheCommonCurrencies(_ locale: String) throws {
        let names = try #require(MoneyLocalization.currencyFullNames[locale])

        for code: CurrencyCode in ["GBP", "USD", "EUR", "JPY"] {
            #expect(names[code] != nil, "\(locale) should name \(code)")
        }
    }

    // CLDR names 164 of the 165 currencies the library ships in English, and three fewer in the
    // other covered locales, so a caller has to cope with a currency having no name.
    @Test("A currency CLDR does not name is absent rather than made up")
    func unnamedCurrenciesAreAbsent() throws {
        let english = try #require(MoneyLocalization.currencyFullNames["en"])

        #expect(english["XAD"] == nil)
        #expect(english.count < Currency.allISO4217.count)
    }
}
