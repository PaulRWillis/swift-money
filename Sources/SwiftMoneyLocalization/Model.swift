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
    package let isoCodeSpacing: String
    // The gap between the amount and a currency's full name.
    package let fullNameSpacing: Spacing

    package init(
        decimalSeparator: String,
        groupingSeparator: GroupingSeparator,
        minusSign: String,
        primaryGroupingSize: GroupingSize,
        secondaryGroupingSize: GroupingSize,
        pattern: MoneyFormatPattern,
        fullNamePattern: FullNameLayout,
        isoCodeSpacing: String,
        fullNameSpacing: Spacing
    ) {
        self.decimalSeparator = decimalSeparator
        self.groupingSeparator = groupingSeparator
        self.minusSign = minusSign
        self.primaryGroupingSize = primaryGroupingSize
        self.secondaryGroupingSize = secondaryGroupingSize
        self.pattern = pattern
        self.fullNamePattern = fullNamePattern
        self.isoCodeSpacing = isoCodeSpacing
        self.fullNameSpacing = fullNameSpacing
    }
}

// A currency's symbol and narrow symbol in one locale, each with the spacing CLDR resolves for it. Only
// currencies whose symbol differs from their code are stored; the rest fall back to the code.
package struct CurrencyDisplay: Equatable {
    package let standardSymbol: String
    package let standardSpacing: String
    package let narrowSymbol: String
    package let narrowSpacing: String

    package init(standardSymbol: String, standardSpacing: String, narrowSymbol: String, narrowSpacing: String) {
        self.standardSymbol = standardSymbol
        self.standardSpacing = standardSpacing
        self.narrowSymbol = narrowSymbol
        self.narrowSpacing = narrowSpacing
    }
}
