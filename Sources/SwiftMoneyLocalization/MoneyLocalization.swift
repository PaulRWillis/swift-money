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
        guard let localeIndex = cldr.locales.index(of: locale) else {
            return nil
        }

        let format = numberFormat(at: localeIndex)
        let code = String(currency.code)
        let display = cldr.currencyDisplays.display(localeIndex: localeIndex, code: currency.code)

        let symbol: String
        let spacing: Spacing
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

        return moneyFormat(symbol: symbol, pattern: format.pattern, gap: spacing.rendered, from: format)
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
        guard let localeIndex = cldr.locales.index(of: locale) else {
            return nil
        }

        // The category first, so only the name the amount calls for is read out of the tables.
        let operands = PluralOperandValues(minorUnits: minorUnits, unitScale: currency.unitScale)
        let category = pluralCategory(of: operands, inLanguageOf: locale)

        guard let name = cldr.currencyFullNames.name(
            localeIndex: localeIndex, code: currency.code, category: category
        ) else {
            return nil
        }

        let format = numberFormat(at: localeIndex)
        let affixes = format.fullNamePattern.affixes(for: category)

        return moneyFormat(
            symbol: name,
            pattern: MoneyFormatPattern(positive: affixes, negative: affixes, accountingNegative: affixes),
            gap: format.fullNameSpacing.rendered,
            from: format
        )
    }

    // The first category whose rule the amount satisfies, in the order CLDR resolves them. CLDR gives
    // `other` no rule at all, so it stands in when none holds, and publishes the rules per language, so
    // the identifier's region plays no part.
    static func pluralCategory(
        of operands: PluralOperandValues,
        inLanguageOf locale: LocaleIdentifier
    ) -> PluralCategory {
        let language = String(locale.value.prefix { $0 != "-" && $0 != "_" })
        let rules = pluralRules[language] ?? [:]

        return PluralCategory.allCases.first { rules[$0]?.matches(operands) == true } ?? .other
    }

    /// Every locale identifier the CLDR data covers, in the blob's sorted order. A caller enumerating
    /// the covered locales reads them from the data rather than repeating a hardcoded list that would
    /// drift as coverage grows.
    package static var coveredLocaleIdentifiers: [String] {
        cldr.locales.identifiers()
    }

    /// What `code` is called in a locale, by plural category, or `nil` when the locale is not covered or
    /// CLDR does not name the currency there.
    package static func fullName(of code: CurrencyCode, locale: LocaleIdentifier) -> CurrencyFullName? {
        cldr.locales.index(of: locale).flatMap {
            cldr.currencyFullNames.name(localeIndex: $0, code: code)
        }
    }

    // Every covered locale's number format, decoded once. A format holds nothing that depends on the
    // currency or the amount, so one decode serves every call for that locale, where decoding it again
    // would rebuild its four strings out of the pool each time.
    private static let numberFormats: [LocaleNumberFormat] = (0 ..< cldr.locales.localeCount).map {
        cldr.numberFormats.numberFormat(localeIndex: LocaleIndex(position: $0))
    }

    private static func numberFormat(at localeIndex: LocaleIndex) -> LocaleNumberFormat {
        numberFormats[localeIndex.position]
    }

    // Every language's plural rules, decoded once from the blob. A language with no rule for a category
    // takes `other`, which carries none; a language absent here does too, through the `?? [:]` above.
    private static let pluralRules = cldr.pluralRules.allRules()

    // The locale's number format with a currency written beside it, however that currency is named.
    private static func moneyFormat(
        symbol: String,
        pattern: MoneyFormatPattern,
        gap: String,
        from format: LocaleNumberFormat
    ) -> MoneyFormat {
        MoneyFormat(
            symbol: symbol,
            pattern: pattern,
            currencySpacing: gap,
            decimalSeparator: format.decimalSeparator,
            grouping: .digits(
                primary: format.primaryGroupingSize,
                secondary: format.secondaryGroupingSize,
                separator: format.groupingSeparator
            ),
            minusSign: format.minusSign
        )
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
