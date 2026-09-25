import SwiftMoneyCore

// The locale-dependent pieces the CLDR tables carry, composed into a `MoneyFormat` at lookup time. The
// public surface is `MoneyLocalization.moneyFormat(for:locale:presentation:)`; `package` so the blob
// decoder can build it and tests can read it.
package struct LocaleNumberFormat: Equatable {
    package let decimalSeparator: String
    package let groupingSeparator: GroupingSeparator
    package let minusSign: String
    package let primaryGroupingSize: GroupingSize
    package let secondaryGroupingSize: GroupingSize
    // How this locale arranges a currency symbol, a sign and the digits, from its CLDR pattern.
    package let pattern: MoneyFormatPattern
    // The same, for a currency written out in words, per plural category, from CLDR's unit patterns.
    // A name never takes accounting parentheses, so this carries no accounting form of its own.
    package let fullNamePattern: FullNameLayout
    // The space between an ISO code (or a code used as a fallback symbol) and the digits.
    package let isoCodeSpacing: Spacing
    // The gap the locale's currency pattern bakes in beside every symbol, glyph included: a non-breaking
    // space in de and fr, none in en. Distinct from `isoCodeSpacing`, which a locale inserts only next to
    // a letter-like symbol. Shipped rendering resolves spacing per currency and does not read this.
    package let symbolSpacing: Spacing
    // The gap between the amount and a currency's full name.
    package let fullNameSpacing: Spacing
    // The glyphs this locale writes the digits with: ASCII, or its own set.
    package let digits: Digits
    // How many whole digits the integer part needs before grouping shows; one for most locales.
    package let minGroupingDigits: MinGroupingDigits
    // Where the locale's own default numbering system sits in the numbering-system section. A request for
    // this system resolves to the baked format unchanged, so `bn_BD@beng` renders as `bn_BD` does.
    package let defaultSystemIndex: SystemIndex

    package init(
        decimalSeparator: String,
        groupingSeparator: GroupingSeparator,
        minusSign: String,
        primaryGroupingSize: GroupingSize,
        secondaryGroupingSize: GroupingSize,
        pattern: MoneyFormatPattern,
        fullNamePattern: FullNameLayout,
        isoCodeSpacing: Spacing,
        symbolSpacing: Spacing,
        fullNameSpacing: Spacing,
        digits: Digits = .ascii,
        minGroupingDigits: MinGroupingDigits = 1,
        defaultSystemIndex: SystemIndex
    ) {
        self.decimalSeparator = decimalSeparator
        self.groupingSeparator = groupingSeparator
        self.minusSign = minusSign
        self.primaryGroupingSize = primaryGroupingSize
        self.secondaryGroupingSize = secondaryGroupingSize
        self.pattern = pattern
        self.fullNamePattern = fullNamePattern
        self.isoCodeSpacing = isoCodeSpacing
        self.symbolSpacing = symbolSpacing
        self.fullNameSpacing = fullNameSpacing
        self.digits = digits
        self.minGroupingDigits = minGroupingDigits
        self.defaultSystemIndex = defaultSystemIndex
    }
}

package extension LocaleNumberFormat {
    // The same format writing a different digit set, for a numbering system that reuses the locale's
    // separators. Everything else — separators, grouping, patterns, spacing — is unchanged.
    func replacingDigits(_ digits: Digits) -> LocaleNumberFormat {
        LocaleNumberFormat(
            decimalSeparator: decimalSeparator,
            groupingSeparator: groupingSeparator,
            minusSign: minusSign,
            primaryGroupingSize: primaryGroupingSize,
            secondaryGroupingSize: secondaryGroupingSize,
            pattern: pattern,
            fullNamePattern: fullNamePattern,
            isoCodeSpacing: isoCodeSpacing,
            symbolSpacing: symbolSpacing,
            fullNameSpacing: fullNameSpacing,
            digits: digits,
            minGroupingDigits: minGroupingDigits,
            defaultSystemIndex: defaultSystemIndex
        )
    }

    // The same format writing a numbering system's own separators and digits, for a system that imposes
    // its own. Grouping sizes, patterns and spacing stay the locale's.
    func replacing(symbols: NumberingSystemSymbols, digits: Digits) -> LocaleNumberFormat {
        LocaleNumberFormat(
            decimalSeparator: symbols.decimalSeparator,
            groupingSeparator: symbols.groupingSeparator,
            minusSign: symbols.minusSign,
            primaryGroupingSize: primaryGroupingSize,
            secondaryGroupingSize: secondaryGroupingSize,
            pattern: pattern,
            fullNamePattern: fullNamePattern,
            isoCodeSpacing: isoCodeSpacing,
            symbolSpacing: symbolSpacing,
            fullNameSpacing: fullNameSpacing,
            digits: digits,
            minGroupingDigits: minGroupingDigits,
            defaultSystemIndex: defaultSystemIndex
        )
    }
}

// A currency's symbol and narrow symbol in one locale, each with the spacing CLDR resolves for it. Only
// currencies whose symbol differs from their code are stored; the rest fall back to the code.
package struct CurrencyDisplay: Equatable {
    package let standardSymbol: String
    package let standardSpacing: Spacing
    package let narrowSymbol: String
    package let narrowSpacing: Spacing

    package init(standardSymbol: String, standardSpacing: Spacing, narrowSymbol: String, narrowSpacing: Spacing) {
        self.standardSymbol = standardSymbol
        self.standardSpacing = standardSpacing
        self.narrowSymbol = narrowSymbol
        self.narrowSpacing = narrowSpacing
    }
}
