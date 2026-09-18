import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

@Suite("Full Name Money Format Tests")
struct FullNameMoneyFormatTests {

    static func currency(_ iso: String) -> Currency {
        guard let code = CurrencyCode(string: iso), let currency = Currency(iso: code) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return currency
    }

    static func formatted(_ minorUnits: Int64, _ iso: String, _ locale: LocaleIdentifier) throws -> String {
        let currency = Self.currency(iso)
        let format = try #require(
            MoneyLocalization.fullNameMoneyFormat(for: currency, minorUnits: minorUnits, locale: locale)
        )
        return format.format(Money(minorUnits: minorUnits, currency: currency))
    }

    @Test("A currency with no fraction digits is named in the singular for one unit")
    func oneWholeUnitIsSingular() throws {
        #expect(try Self.formatted(1, "CLP", "en_US") == "1 Chilean peso")
        #expect(try Self.formatted(2, "CLP", "en_US") == "2 Chilean pesos")
    }

    // The finding this phase is built on: English asks for no fraction digits in its `one` rule, and
    // a currency that shows two can never meet that, however small the amount.
    @Test("A currency showing fraction digits is never named in the singular in English")
    func fractionDigitsRuleOutTheSingular() throws {
        #expect(try Self.formatted(1_00, "GBP", "en_GB") == "1.00 British pounds")
        #expect(try Self.formatted(1, "GBP", "en_GB") == "0.01 British pounds")
    }

    // French asks only that the whole part is zero or one, so it keeps the singular where English
    // does not.
    @Test("French names one euro in the singular even with fraction digits shown")
    func frenchKeepsTheSingular() throws {
        #expect(try Self.formatted(1_00, "EUR", "fr_FR") == "1,00 euro")
        #expect(try Self.formatted(2_00, "EUR", "fr_FR") == "2,00 euros")
    }

    @Test("Japanese writes the name against the amount, with no gap")
    func japaneseHasNoGap() throws {
        #expect(try Self.formatted(1, "JPY", "ja_JP") == "1円")
    }

    @Test("A locale outside the covered set has no full name format")
    func uncoveredLocaleHasNoFormat() {
        let format = MoneyLocalization.fullNameMoneyFormat(
            for: Self.currency("GBP"), minorUnits: 1_00, locale: "zz-ZZ"
        )

        #expect(format == nil)
    }

    // CLDR names 163 of the 165 currencies the library ships in English.
    @Test("A currency CLDR does not name has no full name format")
    func unnamedCurrencyHasNoFormat() {
        let format = MoneyLocalization.fullNameMoneyFormat(
            for: Self.currency("XAD"), minorUnits: 1_00, locale: "en_US"
        )

        #expect(format == nil)
    }

    // A locale's accounting form is part of the pattern that writes a symbol, not a name, so ICU
    // writes "-1.00 British pounds" where the symbol form would give "(£1.00)".
    @Test("A negative keeps its minus sign when the currency is named in full")
    func accountingKeepsTheMinusSign() throws {
        let gbp = Self.currency("GBP")
        let format = try #require(
            MoneyLocalization.fullNameMoneyFormat(for: gbp, minorUnits: -1_00, locale: "en_GB")
        )

        let text = format.format(Money(minorUnits: -1_00, currency: gbp), options: MoneyFormatOptions(sign: .accounting))

        #expect(text == "-1.00 British pounds")
    }
}
