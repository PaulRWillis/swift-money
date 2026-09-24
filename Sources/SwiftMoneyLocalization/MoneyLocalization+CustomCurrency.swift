import SwiftMoneyCore

public extension MoneyLocalization {
    /// The currency format for a custom currency's amount in a locale, or `nil` when the locale is not
    /// covered or the currency has no display there.
    ///
    /// The display comes from the currency type through ``CustomCurrencyFormattable``, so the amount and
    /// its display always agree. The number grammar (separators, grouping, digits, minus) follows the
    /// locale, exactly as it does for a shipped currency.
    ///
    /// ```swift
    /// let format = MoneyLocalization.moneyFormat(for: COIN(minorUnits: 500_00), locale: "en_US")
    /// format.map { COIN(minorUnits: 500_00).formatted(with: $0) }   // "🪙500.00"
    /// ```
    ///
    /// - Parameters:
    ///   - money: The amount whose currency supplies the display.
    ///   - locale: The locale identifier, as ``moneyFormat(for:locale:presentation:)`` takes it.
    ///   - presentation: Whether to show the symbol, the ISO code, or the narrow symbol.
    /// - Returns: A ``MoneyFormat``, or `nil` when the locale is outside the covered set or the currency
    ///   has no display for it.
    static func moneyFormat<C: CustomCurrencyFormattable>(
        for money: MoneyOf<C>,
        locale: LocaleIdentifier,
        presentation: CurrencyPresentation = .standard
    ) -> MoneyFormat? {
        C.display(for: locale).flatMap {
            moneyFormat(for: money.currency, display: $0, locale: locale, presentation: presentation)
        }
    }
}

package extension MoneyLocalization {
    // The building block the generic entry above and the Foundation FormatStyle dispatch share. Not
    // public, so no caller can pair a currency with a display that is not its own.
    static func moneyFormat(
        for currency: Currency,
        display: CustomCurrencyDisplay,
        locale: LocaleIdentifier,
        presentation: CurrencyPresentation
    ) -> MoneyFormat? {
        guard let localeIndex = cldr.locales.index(of: locale) else {
            return nil
        }

        let format = numberFormat(at: localeIndex)
        let form = symbolForm(display, presentation: presentation, code: currency.code)

        return moneyFormat(
            symbol: form.symbol,
            pattern: pattern(for: form.placement, inheriting: format.pattern),
            gap: renderedGap(for: form.spacing, symbol: form.symbol, in: format),
            from: format
        )
    }
}

private extension MoneyLocalization {
    // The symbol string, placement and spacing one presentation resolves to. `.isoCode` renders the code
    // itself, inheriting the locale's placement and letter gap, as the shipped path does; the placement
    // override applies only to `.standard` and `.narrow`.
    static func symbolForm(
        _ display: CustomCurrencyDisplay,
        presentation: CurrencyPresentation,
        code: CurrencyCode
    ) -> (symbol: String, placement: CurrencySymbolPlacement, spacing: CurrencySpacing) {
        switch presentation {
        case .standard:
            (display.symbol.rawValue, display.placement, display.spacing)
        case .narrow:
            (
                (display.narrowSymbol ?? display.symbol).rawValue,
                display.placement,
                display.narrowSpacing ?? display.spacing
            )
        case .isoCode:
            (String(code), .automatic, .automatic)
        }
    }

    // The affix arrangement a placement renders with. `.automatic` keeps the locale's own pattern, so it
    // inherits the side, accounting form and directional marks. A forced side synthesizes a pattern and
    // uses a plain minus for negatives, since a caller-chosen side has no CLDR arrangement to inherit.
    static func pattern(
        for placement: CurrencySymbolPlacement,
        inheriting localePattern: MoneyFormatPattern
    ) -> MoneyFormatPattern {
        let affixes: MoneyFormatAffixes
        switch placement {
        case .automatic:
            return localePattern
        case .leading:
            affixes = MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: [])
        case .trailing:
            affixes = MoneyFormatAffixes(prefix: [.sign], suffix: [.currencySpacing, .currency])
        }

        return MoneyFormatPattern(positive: affixes, negative: affixes, accountingNegative: affixes)
    }

    // The gap between a symbol and the digits. `.fixed` is the exact gap; `.automatic` reads the locale,
    // taking the letter gap for an ASCII letters/digits code and the pattern gap for a glyph.
    static func renderedGap(
        for spacing: CurrencySpacing,
        symbol: String,
        in format: LocaleNumberFormat
    ) -> String {
        switch spacing {
        case .fixed(let gap):
            gap.rendered
        case .automatic:
            isASCIIAlphanumeric(symbol) ? format.isoCodeSpacing.rendered : format.symbolSpacing.rendered
        }
    }

    // Whether every byte of the symbol is an ASCII letter or digit. A byte-range test, so it needs no
    // Unicode tables and runs under Embedded; it approximates CLDR's boundary rule (see ``CurrencySpacing``).
    static func isASCIIAlphanumeric(_ symbol: String) -> Bool {
        symbol.utf8.allSatisfy { byte in
            (UInt8(ascii: "A") ... UInt8(ascii: "Z")).contains(byte)
                || (UInt8(ascii: "a") ... UInt8(ascii: "z")).contains(byte)
                || (UInt8(ascii: "0") ... UInt8(ascii: "9")).contains(byte)
        }
    }
}
