import SwiftMoneyCore

/// Locale-aware currency formats sourced from CLDR, with no dependency on Foundation or ICU. Feed the
/// returned ``MoneyFormat`` to the Core engine to render an amount for a locale on any platform,
/// including Embedded. The Foundation `MoneyOf.FormatStyle` uses this where a locale is covered and
/// falls back to ICU otherwise.
///
/// The data is generated from CLDR by the `GenerateSwiftMoneyLocalization` tool; it currently covers a
/// small starter set of locales and grows over time.
public enum MoneyLocalization {

    /// The currency format for an amount's currency in a locale, or `nil` if the locale is not covered.
    ///
    /// ```swift
    /// let format = MoneyLocalization.moneyFormat(for: .gbp, locale: "en-GB")   // £ before, ","/"."
    /// format.map { GBP(minorUnits: 4_99).formatted(with: $0) }                 // "£4.99"
    /// ```
    ///
    /// - Parameters:
    ///   - currency: The currency to format. Its code selects the symbol; its scale sets the digits.
    ///   - locale: The locale identifier, e.g. `"en-GB"` or `"de_DE"` (either separator; a
    ///     language-region identifier falls back to its language).
    ///   - presentation: Whether to show the symbol, the ISO code, or the narrow symbol.
    /// - Returns: A ``MoneyFormat``, or `nil` when the locale is outside the covered set.
    public static func moneyFormat(
        for currency: Currency,
        locale: LocaleIdentifier,
        presentation: CurrencyPresentation = .standard
    ) -> MoneyFormat? {
        guard let (key, format) = resolve(locale) else {
            return nil
        }

        let code = String(currency.code)
        let display = currencyDisplays[key]?[code]

        let symbol: String
        let spacing: String
        switch presentation {
        case .standard:
            symbol = display?.standardSymbol ?? code
            spacing = display?.standardSpacing ?? format.isoCodeSpacing
        case .narrow:
            symbol = display?.narrowSymbol ?? code
            spacing = display?.narrowSpacing ?? format.isoCodeSpacing
        case .isoCode:
            symbol = code
            spacing = format.isoCodeSpacing
        }

        return MoneyFormat(
            symbol: symbol,
            placement: format.placement,
            spacing: spacing,
            decimalSeparator: format.decimalSeparator,
            groupingSeparator: format.groupingSeparator,
            primaryGroupingSize: format.primaryGroupingSize,
            secondaryGroupingSize: format.secondaryGroupingSize,
            minusSign: format.minusSign
        )
    }

    // Resolves an identifier to a table entry, normalizing the separator and falling back from a
    // language-region tag to the bare language, as CLDR inheritance does (`de_DE` → `de`).
    static func resolve(_ locale: LocaleIdentifier) -> (key: String, format: LocaleNumberFormat)? {
        let normalized = String(locale.value.map { $0 == "_" ? "-" : $0 })
        if let format = numberFormats[normalized] {
            return (normalized, format)
        }

        let language = String(normalized.prefix { $0 != "-" })
        if let format = numberFormats[language] {
            return (language, format)
        }

        return nil
    }
}

/// A locale identifier such as `"en-GB"`. A plain wrapper so the public API names a locale rather than
/// an untyped string; either `-` or `_` separates language and region.
public struct LocaleIdentifier: Hashable, Sendable, ExpressibleByStringLiteral {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public init(stringLiteral value: String) {
        self.value = value
    }
}

/// How a currency is named in formatted output. The non-ICU counterpart to the presentations
/// `Decimal.FormatStyle.Currency` offers, minus `fullName`, which the localization tables do not carry
/// yet.
public enum CurrencyPresentation: Hashable, Sendable {
    /// The currency's symbol, e.g. `£`.
    case standard
    /// The ISO code, e.g. `GBP`.
    case isoCode
    /// The narrow symbol, e.g. `$` where the standard symbol is `US$`.
    case narrow
}
