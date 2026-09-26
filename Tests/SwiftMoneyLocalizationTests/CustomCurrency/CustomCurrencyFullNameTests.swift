import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Naming a custom currency in full: plural-aware, joined the way the locale joins a name, with the
// caller supplying the names and, optionally, the gap.
@Suite("Custom Currency Full Name Tests")
struct CustomCurrencyFullNameTests {

    static func currency(_ code: CurrencyCode, scale: UnitScale = 100) -> Currency {
        guard let currency = Currency(code: code, unitScale: scale) else {
            preconditionFailure("\(code) must not be a currency the library ships at another scale")
        }
        return currency
    }

    static func amount(_ minorUnits: Int64, _ currency: Currency) -> Money {
        Money(minorUnits: minorUnits, currency: currency)
    }

    @Test("A currency name rejects an empty string but accepts a non-empty one")
    func nameValidation() {
        let empty = String(repeating: " ", count: 0)
        #expect(CurrencyName(empty) == nil)

        let text = String(repeating: "M", count: 1)
        #expect(CurrencyName(text) == "M")
    }

    @Test("An empty currency name literal traps")
    func emptyNameLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let _: CurrencyName = ""
        }
    }

    // The singular name is used for one whole unit and the plural for the rest, through the type.
    @Test("A whole-unit currency is named in the singular for one unit")
    func pluralAwareNaming() throws {
        let one = MoneyOf<Points>(minorUnits: 1)
        let two = MoneyOf<Points>(minorUnits: 2)

        let format1 = try #require(MoneyLocalization.fullNameMoneyFormat(for: one, locale: "en_US"))
        #expect(format1.format(one) == "1 point")

        let format2 = try #require(MoneyLocalization.fullNameMoneyFormat(for: two, locale: "en_US"))
        #expect(format2.format(two) == "2 points")
    }

    // A negative is named in full with a plain minus, never accounting parentheses.
    @Test("A negative full name keeps its minus sign")
    func negativeKeepsMinus() throws {
        let money = MoneyOf<Points>(minorUnits: -2)
        let format = try #require(MoneyLocalization.fullNameMoneyFormat(for: money, locale: "en_US"))

        #expect(format.format(money, options: MoneyFormatOptions(sign: .accounting)) == "-2 points")
    }

    // The caller chooses the width of the name set: a short set renders a short name.
    @Test("A short name set renders the short name")
    func shortNameSet() throws {
        let currency = Self.currency("PNT")
        let names = CustomCurrencyNames(other: "pts")
        let format = try #require(
            MoneyLocalization.fullNameMoneyFormat(for: currency, names: names, minorUnits: 500_00, locale: "en_US")
        )

        #expect(format.format(Self.amount(500_00, currency)) == "500.00 pts")
    }

    @Test("A fixed name gap renders a tight join")
    func tightJoin() throws {
        let currency = Self.currency("PNT")
        let names = CustomCurrencyNames(other: "pts", spacing: .fixed(.none))
        let format = try #require(
            MoneyLocalization.fullNameMoneyFormat(for: currency, names: names, minorUnits: 500_00, locale: "en_US")
        )

        #expect(format.format(Self.amount(500_00, currency)) == "500.00pts")
    }

    // A name-first locale writes the caller's name before the amount, the join shape coming from the
    // locale rather than the caller.
    @Test("A name-first locale writes the name before the amount")
    func nameFirstLocale() throws {
        let currency = Self.currency("CON")
        let names = CustomCurrencyNames(other: "coins")
        let format = try #require(
            MoneyLocalization.fullNameMoneyFormat(for: currency, names: names, minorUnits: 5_00, locale: "to")
        )

        let text = format.format(Self.amount(5_00, currency))
        #expect(text.hasPrefix("coins"))
        #expect(text.hasSuffix("5.00"))
    }

    // A category with no supplied name falls back to `other`.
    @Test("A category with no name of its own falls back to other")
    func categoryFallsBackToOther() throws {
        let currency = Self.currency("PTC", scale: 1)
        let names = CustomCurrencyNames(other: "coins")   // no `.one`
        let format = try #require(
            MoneyLocalization.fullNameMoneyFormat(for: currency, names: names, minorUnits: 1, locale: "en_US")
        )

        #expect(format.format(Self.amount(1, currency)) == "1 coins")
    }

    // The locale's own plural rules decide the category, so the same amount picks a different name in a
    // locale that keeps the singular for a fractional one-unit amount.
    @Test("A locale's own plural rules pick the name")
    func localeRulesPickTheName() throws {
        let currency = Self.currency("GMS")
        let names = CustomCurrencyNames(other: "gems", byCategory: [.one: "gem"])

        let french = try #require(
            MoneyLocalization.fullNameMoneyFormat(for: currency, names: names, minorUnits: 1_00, locale: "fr_FR")
        )
        #expect(french.format(Self.amount(1_00, currency)) == "1,00 gem")

        let english = try #require(
            MoneyLocalization.fullNameMoneyFormat(for: currency, names: names, minorUnits: 1_00, locale: "en_US")
        )
        #expect(english.format(Self.amount(1_00, currency)) == "1.00 gems")
    }

    @Test("An uncovered locale has no custom full name")
    func uncoveredLocaleIsNil() {
        let currency = Self.currency("GMS")
        let names = CustomCurrencyNames(other: "gems")

        #expect(
            MoneyLocalization.fullNameMoneyFormat(for: currency, names: names, minorUnits: 1_00, locale: "zz-ZZ") == nil
        )
    }

    @Test("A currency that supplies no names has no custom full name")
    func noNamesIsNil() {
        #expect(MoneyLocalization.fullNameMoneyFormat(for: MoneyOf<PlainCoin>(minorUnits: 1), locale: "en_US") == nil)
    }
}

// A whole-unit custom currency (no fraction digits) that names itself in full.
private enum Points: CustomCurrencyFormattable {
    static let currency: Currency = {
        guard let currency = Currency(code: "PTS", unitScale: 1) else {
            preconditionFailure("PTS must not be a currency the library ships")
        }
        return currency
    }()

    static func display(for locale: LocaleIdentifier) -> CustomCurrencyDisplay? {
        CustomCurrencyDisplay(symbol: "P")
    }

    static func names(for locale: LocaleIdentifier) -> CustomCurrencyNames? {
        CustomCurrencyNames(other: "points", byCategory: [.one: "point"])
    }
}

// A custom currency with a symbol but no full names, so its full-name format is nil.
private enum PlainCoin: CustomCurrencyFormattable {
    static let currency: Currency = {
        guard let currency = Currency(code: "PLN2", unitScale: 100) else {
            preconditionFailure("PLN2 must not be a currency the library ships")
        }
        return currency
    }()

    static func display(for locale: LocaleIdentifier) -> CustomCurrencyDisplay? {
        CustomCurrencyDisplay(symbol: "🪙")
    }
}
