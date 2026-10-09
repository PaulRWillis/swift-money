import SwiftMoneyCore

/// Locale-aware currency formats sourced from CLDR, with no dependency on Foundation or ICU. Feed the
/// returned ``MoneyFormat`` to the Core engine to render an amount for a locale on any platform,
/// including Embedded. The Foundation `MoneyOf.FormatStyle` uses this where a locale is covered and
/// falls back to ICU otherwise.
///
/// The data is generated from CLDR by the `GenerateSwiftMoneyLocalization` tool, which emits every
/// locale it can render and lists the rest, with the reason for each, in `UnsupportedLocales.md`
/// beside the generated tables. Coverage therefore widens as those reasons are worked through.
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
    ///   - locale: The locale identifier, with `-` or `_` between subtags, in any letter case, such as
    ///     `"en-GB"` or `"de_DE"`. A language-region identifier falls back to its language.
    ///   - presentation: Whether to show the symbol, the ISO code, or the narrow symbol.
    ///   - numberingSystem: The digits and separators to render in. ``NumberingSystemSelection/automatic``
    ///     (the default) uses the locale's own default system, so the output is unchanged.
    /// - Returns: A ``MoneyFormat``, or `nil` when the locale is outside the covered set.
    public static func moneyFormat(
        for currency: Currency,
        locale: LocaleIdentifier,
        presentation: CurrencyPresentation = .standard,
        numberingSystem: NumberingSystemSelection = .automatic
    ) -> MoneyFormat? {
        guard let localeIndex = cldr.locales.index(of: locale) else {
            return nil
        }

        let format = numberFormat(at: localeIndex, numberingSystem: numberingSystem)
        let display = cldr.currencyDisplays.display(localeIndex: localeIndex, code: currency.code)

        // Build the code string only where it is used: as the fallback when a locale has no symbol, and
        // for the ISO presentation. The common case (a currency with a symbol) never builds it. An ISO
        // code is always letters, so a display-less fallback takes the letter column too.
        let symbol: String
        let spacing: Spacing
        let form: SymbolForm
        switch presentation {
        case .standard:
            symbol = display?.standardSymbol ?? String(currency.code)
            spacing = display?.standardSpacing ?? format.isoCodeSpacing
            form = display?.standardForm ?? .letters
        case .narrow:
            symbol = display?.narrowSymbol ?? String(currency.code)
            spacing = display?.narrowSpacing ?? format.isoCodeSpacing
            form = display?.narrowForm ?? .letters
        case .isoCode:
            symbol = String(currency.code)
            spacing = format.isoCodeSpacing
            form = .letters
        }

        let (standard, accounting) = resolvedArrangements(for: form, in: format)

        return moneyFormat(
            symbol: symbol,
            pattern: standard.pattern,
            primaryGroupingSize: standard.primaryGroupingSize,
            secondaryGroupingSize: standard.secondaryGroupingSize,
            gap: spacing.rendered,
            from: format,
            accountingArrangement: accounting
        )
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
    ///   - numberingSystem: The digits and separators to render in. ``NumberingSystemSelection/automatic``
    ///     (the default) uses the locale's own default system, so the output is unchanged.
    /// - Returns: A ``MoneyFormat``, or `nil` when the locale is outside the covered set or CLDR
    ///   gives the currency no name there.
    public static func fullNameMoneyFormat(
        for currency: Currency,
        minorUnits: Int64,
        locale: LocaleIdentifier,
        numberingSystem: NumberingSystemSelection = .automatic
    ) -> MoneyFormat? {
        guard let localeIndex = cldr.locales.index(of: locale) else {
            return nil
        }

        // The category first, so only the name the amount calls for is read out of the tables.
        let operands = PluralOperandValues(minorUnits: minorUnits, unitScale: currency.unitScale)

        guard
            let category = pluralCategory(of: operands, at: localeIndex),
            let name = cldr.currencyFullNames.name(
                localeIndex: localeIndex, code: currency.code, category: category
            )
        else {
            return nil
        }

        let format = numberFormat(at: localeIndex, numberingSystem: numberingSystem)
        let affixes = format.fullNamePattern.affixes(for: category)

        return moneyFormat(
            symbol: name,
            pattern: MoneyFormatPattern(positive: affixes, negative: affixes, accountingNegative: affixes),
            primaryGroupingSize: format.standardArrangement.primaryGroupingSize,
            secondaryGroupingSize: format.standardArrangement.secondaryGroupingSize,
            gap: format.fullNameSpacing.rendered,
            from: format
        )
    }

    /// Returns the plural category an amount takes in a locale.
    ///
    /// The category is the first whose rule the amount satisfies, in the order CLDR resolves them, and
    /// ``PluralCategory/other`` when none holds, since CLDR gives `other` no rule. The rules are the
    /// locale's language's, so a region names amounts as its language does.
    ///
    /// ```swift
    /// let one = PluralOperandValues(minorUnits: 1, unitScale: Currency.jpy.unitScale)
    /// MoneyLocalization.pluralCategory(of: one, at: englishIndex)  // .one
    /// ```
    ///
    /// - Parameters:
    ///   - operands: The amount's plural operands.
    ///   - localeIndex: The locale's position, as ``LocaleTable/index(of:)`` returns it.
    /// - Returns: The amount's category, or `nil` when the data holds no rules for the locale's
    ///   language.
    package static func pluralCategory(
        of operands: PluralOperandValues,
        at localeIndex: LocaleIndex
    ) -> PluralCategory? {
        pluralRulesByLocale[localeIndex.position].map { rules in
            PluralCategory.allCases.first { rules[$0]?.matches(operands) == true } ?? .other
        }
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

    // Not private: the custom-currency builder in another file resolves a locale's format through this.
    static func numberFormat(at localeIndex: LocaleIndex) -> LocaleNumberFormat {
        numberFormats[localeIndex.position]
    }

    // The locale's format rendered in a chosen numbering system, or its baked default when the selection is
    // automatic. The automatic and own-default paths return the baked format untouched, so they stay
    // byte-identical.
    static func numberFormat(
        at localeIndex: LocaleIndex,
        numberingSystem: NumberingSystemSelection
    ) -> LocaleNumberFormat {
        let baked = numberFormat(at: localeIndex)
        return resolvedNumbering(at: localeIndex, for: numberingSystem, baked: baked).applied(to: baked)
    }

    // How a requested system resolves against the baked format: unchanged when the selection is automatic,
    // when the system is not modelled, or when it is the locale's own default; a digit swap for a reuse
    // system; or the system's separators (default or per-locale override) plus its digits for an imposing one.
    private static func resolvedNumbering(
        at localeIndex: LocaleIndex,
        for selection: NumberingSystemSelection,
        baked: LocaleNumberFormat
    ) -> ResolvedNumbering {
        guard
            case .explicit(let numberingSystem) = selection,
            let systemIndex = systemIndex(of: numberingSystem),
            systemIndex != baked.defaultSystemIndex
        else {
            return .baked
        }

        let digits = cldr.numberingSystems.digits(at: systemIndex)

        switch cldr.numberingSystems.provenance(at: systemIndex) {
        case .reusesLocale:
            return .swapDigits(digits)
        case .imposesOwn(let defaultSymbols):
            let symbols = cldr.numberingSystemOverrides.symbols(
                localeIndex: localeIndex, systemIndex: systemIndex
            ) ?? defaultSymbols
            return .systemSymbols(symbols, digits: digits)
        }
    }

    /// Each covered locale's plural rules by category, at the locale's position, decoded once from the
    /// blob. An entry is `nil` when the blob holds no rules for the locale's language.
    private static let pluralRulesByLocale: [[PluralCategory: PluralRule]?] = {
        let rulesByLanguage = cldr.pluralRules.allRules()

        return cldr.locales.identifiers().map { identifier in
            rulesByLanguage[String(identifier.prefix { $0 != "-" })]
        }
    }()

    // Each supported system's index by name, built once, so resolving a requested system is a dictionary
    // lookup rather than a binary search over the pooled names on every format.
    private static let systemIndicesByName: [String: SystemIndex] = Dictionary(
        uniqueKeysWithValues: (0 ..< cldr.numberingSystems.count).map {
            let index = SystemIndex(position: $0)
            return (cldr.numberingSystems.name(at: index), index)
        }
    )

    private static func systemIndex(of numberingSystem: NumberingSystem) -> SystemIndex? {
        systemIndicesByName[numberingSystem.identifier]
    }

    // The locale's number format with a currency written beside it, however that currency is named.
    // Not private: the custom-currency builder in another file composes a format through this too.
    //
    // `primaryGroupingSize`/`secondaryGroupingSize` are separate from `pattern` rather than a single
    // `CurrencyArrangement`, because two of this function's four callers (a full name's join, and a
    // custom currency's caller-forced side) pair the locale's own sizes with a pattern that is not
    // itself an interned arrangement.
    static func moneyFormat(
        symbol: String,
        pattern: MoneyFormatPattern,
        primaryGroupingSize: GroupingSize,
        secondaryGroupingSize: GroupingSize,
        gap: String,
        from format: LocaleNumberFormat,
        accountingArrangement: MoneyFormat.Arrangement? = nil
    ) -> MoneyFormat {
        MoneyFormat(
            symbol: symbol,
            pattern: pattern,
            currencySpacing: gap,
            decimalSeparator: format.decimalSeparator,
            grouping: .digits(
                primary: primaryGroupingSize,
                secondary: secondaryGroupingSize,
                separator: format.groupingSeparator,
                minGroupingDigits: format.minGroupingDigits
            ),
            minusSign: format.minusSign,
            digits: format.digits,
            accountingArrangement: accountingArrangement
        )
    }

    // The standard-presentation arrangement to render every sign strategy with, and the engine-level
    // accounting override to render `.accounting` with — `nil` when accounting does not move anything
    // `pattern.accountingNegative` does not already say. Both cells are read from the locale's own
    // baked variants, which are themselves `nil` whenever they equal the locale's plain standard
    // arrangement (an in-band sentinel resolved once, at blob-decode time, in `NumberFormatTable`).
    //
    // Each of `format`'s three variant cells is baked *independently*, always relative to the plain
    // standard arrangement — never relative to one another — so two cells that happen to share the same
    // underlying CLDR text (as `no`'s `accountingArrangement` and `alphaAccountingArrangement` do)
    // resolve to equal values without this function having to know that. That equality is exactly what
    // the final comparison below tests: when the accounting side has nothing left to add once the
    // letter-form column is already chosen, this returns `nil` and the fast path stays untouched.
    private static func resolvedArrangements(
        for form: SymbolForm,
        in format: LocaleNumberFormat
    ) -> (standard: CurrencyArrangement, accounting: MoneyFormat.Arrangement?) {
        let useAlpha = form == .letters
        let standard = useAlpha ? (format.alphaArrangement ?? format.standardArrangement) : format.standardArrangement
        let accountingBase = useAlpha
            ? (format.alphaAccountingArrangement ?? format.standardArrangement)
            : (format.accountingArrangement ?? format.standardArrangement)

        guard accountingBase != standard else {
            return (standard, nil)
        }
        return (standard, engineArrangement(accountingBase, from: format))
    }

    // A baked `CurrencyArrangement` (Localization) as the engine's own `MoneyFormat.Arrangement`
    // (Core), with the group separator and minimum grouping digits — known only once a locale is
    // resolved — assembled alongside the sizes the arrangement itself carries. Not private: the
    // custom-currency builder in another file resolves its own accounting arrangement through this too.
    static func engineArrangement(_ arrangement: CurrencyArrangement, from format: LocaleNumberFormat) -> MoneyFormat.Arrangement {
        MoneyFormat.Arrangement(
            pattern: arrangement.pattern,
            grouping: .digits(
                primary: arrangement.primaryGroupingSize,
                secondary: arrangement.secondaryGroupingSize,
                separator: format.groupingSeparator,
                minGroupingDigits: format.minGroupingDigits
            )
        )
    }

}
