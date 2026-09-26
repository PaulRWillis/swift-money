import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Rendering a custom currency's symbol through the public generic entry and the package builder. The
// number grammar follows the locale; only the display (symbol, placement, spacing) is the caller's.
@Suite("Custom Currency Money Format Tests")
struct CustomCurrencyMoneyFormatTests {

    // A currency the library does not ship, at a definite code and scale (100, two decimal places).
    static func currency(_ code: CurrencyCode, scale: UnitScale = 100) -> Currency {
        guard let currency = Currency(code: code, unitScale: scale) else {
            preconditionFailure("\(code) must not be a currency the library ships at another scale")
        }
        return currency
    }

    static func amount(_ minorUnits: Int64, _ currency: Currency) -> Money {
        Money(minorUnits: minorUnits, currency: currency)
    }

    @Test("A currency symbol rejects an empty string but accepts a non-empty one")
    func symbolValidation() {
        // A non-literal empty string reaches `init?(_:)`; an empty literal would trap instead.
        let empty = String(repeating: " ", count: 0)
        #expect(CurrencySymbol(empty) == nil)

        let text = String(repeating: "M", count: 1)
        #expect(CurrencySymbol(text) == "M")
    }

    @Test("An empty currency symbol literal traps")
    func emptySymbolLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let _: CurrencySymbol = ""
        }
    }

    // The generic entry reads the display from the type, proving the binding, and a glyph takes the
    // locale's pattern gap: none in en, a non-breaking space in de.
    @Test("A custom glyph takes the locale's pattern gap, via the type")
    func glyphPatternGap() throws {
        let money = MoneyOf<Gems>(minorUnits: 500_00)

        let en = try #require(MoneyLocalization.moneyFormat(for: money, locale: "en_US"))
        #expect(en.format(money) == "💎500.00")

        let de = try #require(MoneyLocalization.moneyFormat(for: money, locale: "de_DE"))
        #expect(de.format(money) == "500,00\u{00A0}💎")
    }

    // A letters code takes the locale's letter gap (a non-breaking space), whichever side the locale
    // puts the currency on: leading in en, trailing in de.
    @Test("A letters code takes the locale's letter gap")
    func lettersLetterGap() throws {
        let gem = Self.currency("GEM")
        let display = CustomCurrencyDisplay(symbol: "GEM")

        let en = try #require(MoneyLocalization.moneyFormat(for: gem, display: display, locale: "en_US", presentation: .standard))
        #expect(en.format(Self.amount(500_00, gem)) == "GEM\u{00A0}500.00")

        let de = try #require(MoneyLocalization.moneyFormat(for: gem, display: display, locale: "de_DE", presentation: .standard))
        #expect(de.format(Self.amount(500_00, gem)) == "500,00\u{00A0}GEM")
    }

    // The inherit path (placement `.automatic`) follows the locale for the sign and its accounting form,
    // which is parentheses in en.
    @Test("A custom symbol inherits the locale's sign placement and accounting")
    func inheritsSignAndAccounting() throws {
        let money = MoneyOf<Gems>(minorUnits: -123_00)
        let format = try #require(MoneyLocalization.moneyFormat(for: money, locale: "en_US"))

        #expect(format.format(money) == "-💎123.00")
        #expect(format.format(money, options: MoneyFormatOptions(sign: .accounting)) == "(💎123.00)")
    }

    @Test("A leading override forces the symbol before the digits")
    func leadingOverride() throws {
        let gem = Self.currency("GEM")
        let display = CustomCurrencyDisplay(symbol: "💎", placement: .leading)

        let de = try #require(MoneyLocalization.moneyFormat(for: gem, display: display, locale: "de_DE", presentation: .standard))
        #expect(de.format(Self.amount(500_00, gem)) == "💎\u{00A0}500,00")
    }

    @Test("A trailing override forces the symbol after the digits, with a plain minus for accounting")
    func trailingOverride() throws {
        let gem = Self.currency("GEM")
        let display = CustomCurrencyDisplay(symbol: "💎", placement: .trailing)
        let format = try #require(MoneyLocalization.moneyFormat(for: gem, display: display, locale: "en_US", presentation: .standard))

        #expect(format.format(Self.amount(500_00, gem)) == "500.00💎")

        let accounting = format.format(Self.amount(-500_00, gem), options: MoneyFormatOptions(sign: .accounting))
        #expect(accounting == "-500.00💎")
        #expect(!accounting.contains("("))
    }

    // A fixed gap overrides whatever the locale would pick: `.none` drops the letter gap, and a space
    // adds one where the pattern gap would be empty.
    @Test("A fixed spacing overrides the locale's gap")
    func fixedSpacing() throws {
        let gem = Self.currency("GEM")

        let tight = CustomCurrencyDisplay(symbol: "GEM", spacing: .fixed(.none))
        let f1 = try #require(MoneyLocalization.moneyFormat(for: gem, display: tight, locale: "en_US", presentation: .standard))
        #expect(f1.format(Self.amount(500_00, gem)) == "GEM500.00")

        let spaced = CustomCurrencyDisplay(symbol: "💎", spacing: .fixed(.nonBreakingSpace))
        let f2 = try #require(MoneyLocalization.moneyFormat(for: gem, display: spaced, locale: "en_US", presentation: .standard))
        #expect(f2.format(Self.amount(500_00, gem)) == "💎\u{00A0}500.00")
    }

    @Test("The narrow presentation reuses the symbol when no narrow symbol is set")
    func narrowFallsBackToSymbol() throws {
        let gem = Self.currency("GEM")
        let display = CustomCurrencyDisplay(symbol: "💎")
        let format = try #require(MoneyLocalization.moneyFormat(for: gem, display: display, locale: "en_US", presentation: .narrow))

        #expect(format.format(Self.amount(500_00, gem)) == "💎500.00")
    }

    @Test("The narrow presentation uses a distinct narrow symbol and its spacing")
    func narrowUsesItsOwnSymbol() throws {
        let gem = Self.currency("GEM")
        let display = CustomCurrencyDisplay(symbol: "US$", narrowSymbol: "$", narrowSpacing: .fixed(.none))
        let format = try #require(MoneyLocalization.moneyFormat(for: gem, display: display, locale: "en_US", presentation: .narrow))

        #expect(format.format(Self.amount(500_00, gem)) == "$500.00")
    }

    @Test("The ISO presentation renders the code with the locale's ISO gap")
    func isoCodeRendersTheCode() throws {
        let gem = Self.currency("GEM")
        let display = CustomCurrencyDisplay(symbol: "💎", placement: .trailing)
        let format = try #require(MoneyLocalization.moneyFormat(for: gem, display: display, locale: "en_US", presentation: .isoCode))

        // The ISO code, inheriting the locale placement and letter gap, whatever the placement override.
        #expect(format.format(Self.amount(500_00, gem)) == "GEM\u{00A0}500.00")
    }

    @Test("An uncovered locale has no custom format")
    func uncoveredLocaleIsNil() {
        let gem = Self.currency("GEM")
        let display = CustomCurrencyDisplay(symbol: "💎")

        #expect(MoneyLocalization.moneyFormat(for: gem, display: display, locale: "zz-ZZ", presentation: .standard) == nil)
    }

    @Test("A currency whose display is nil has no custom format")
    func nilDisplayIsNil() {
        #expect(MoneyLocalization.moneyFormat(for: MoneyOf<Unshown>(minorUnits: 1), locale: "en_US") == nil)
    }

    @Test("A shipped currency's symbol format is unchanged")
    func shippedCurrencyUnchanged() throws {
        let code = try #require(CurrencyCode(string: "GBP"))
        let gbp = try #require(Currency(iso: code))
        let format = try #require(MoneyLocalization.moneyFormat(for: gbp, locale: "en_US"))

        #expect(format.format(Self.amount(500_00, gbp)) == "£500.00")
    }
}

// A custom currency that shows a glyph. Declares its display on the type, the goal shape.
private enum Gems: CustomCurrencyFormattable {
    static let currency: Currency = {
        guard let currency = Currency(code: "GEM", unitScale: 100) else {
            preconditionFailure("GEM must not be a currency the library ships")
        }
        return currency
    }()

    static func display(for locale: LocaleIdentifier) -> CustomCurrencyDisplay? {
        CustomCurrencyDisplay(symbol: "💎")
    }
}

// A custom currency that supplies no display, so its amounts fall back to today's behavior.
private enum Unshown: CustomCurrencyFormattable {
    static let currency: Currency = {
        guard let currency = Currency(code: "UNS", unitScale: 100) else {
            preconditionFailure("UNS must not be a currency the library ships")
        }
        return currency
    }()

    static func display(for locale: LocaleIdentifier) -> CustomCurrencyDisplay? {
        nil
    }
}
