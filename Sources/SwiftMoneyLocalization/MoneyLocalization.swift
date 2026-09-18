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

        return moneyFormat(symbol: symbol, placement: format.placement, spacing: spacing, from: format)
    }

    /// The currency format for one amount, naming the currency in full, as in "British pounds".
    ///
    /// The name depends on the amount, because a locale may name one unit differently from two, so
    /// this takes the amount where ``moneyFormat(for:locale:presentation:)`` takes a presentation.
    ///
    /// ```swift
    /// let format = MoneyLocalization.fullNameMoneyFormat(for: .gbp, minorUnits: 4_99, locale: "en-GB")
    /// format.map { GBP(minorUnits: 4_99).formatted(with: $0) }    // "4.99 British pounds"
    /// ```
    ///
    /// - Parameters:
    ///   - currency: The currency to name. Its scale decides both the digits and, through them, the
    ///     plural form: a currency showing fraction digits is never named in the singular.
    ///   - minorUnits: The amount, in the currency's smallest units.
    ///   - locale: The locale identifier, as ``moneyFormat(for:locale:presentation:)`` takes it.
    /// - Returns: A ``MoneyFormat``, or `nil` when the locale is outside the covered set or CLDR
    ///   gives the currency no name there.
    public static func fullNameMoneyFormat(
        for currency: Currency,
        minorUnits: Int64,
        locale: LocaleIdentifier
    ) -> MoneyFormat? {
        guard let (key, format) = resolve(locale), let names = currencyFullNames[key]?[currency.code] else {
            return nil
        }

        let operands = PluralOperandValues(minorUnits: minorUnits, unitScale: currency.unitScale)
        let category = pluralCategory(of: operands, in: key)

        return moneyFormat(
            symbol: names.name(for: category),
            placement: .after,
            spacing: format.fullNameSpacing.rendered,
            from: format
        )
    }

    // The first category whose rule the amount satisfies, in the order CLDR resolves them. CLDR gives
    // `other` no rule at all, so it stands in when none holds.
    static func pluralCategory(of operands: PluralOperandValues, in localeKey: String) -> PluralCategory {
        let language = String(localeKey.prefix { $0 != "-" })
        let rules = pluralRules[language] ?? [:]

        return PluralCategory.allCases.first { rules[$0]?.matches(operands) == true } ?? .other
    }

    // The locale's number format with a currency written beside it, however that currency is named.
    private static func moneyFormat(
        symbol: String,
        placement: MoneyFormat.SymbolPlacement,
        spacing: String,
        from format: LocaleNumberFormat
    ) -> MoneyFormat {
        MoneyFormat(
            symbol: symbol,
            placement: placement,
            spacing: spacing,
            decimalSeparator: format.decimalSeparator,
            grouping: .digits(
                primary: format.primaryGroupingSize,
                secondary: format.secondaryGroupingSize,
                separator: format.groupingSeparator
            ),
            accountingNegative: format.accountingNegative,
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

/// How a currency is named in formatted output, where the naming does not depend on the amount.
/// A currency's full name does, so ``MoneyLocalization/fullNameMoneyFormat(for:minorUnits:locale:)``
/// takes the amount instead of one of these.
public enum CurrencyPresentation: Hashable, Sendable {
    /// The currency's symbol, e.g. `£`.
    case standard
    /// The ISO code, e.g. `GBP`.
    case isoCode
    /// The narrow symbol, e.g. `$` where the standard symbol is `US$`.
    case narrow
}
