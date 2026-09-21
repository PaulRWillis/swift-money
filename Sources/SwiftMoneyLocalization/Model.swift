import SwiftMoneyCore

// The locale-dependent pieces the generated CLDR tables carry, composed into a `MoneyFormat` at lookup
// time. Internal — the public surface is `MoneyLocalization.moneyFormat(for:locale:presentation:)`.
struct LocaleNumberFormat {
    let decimalSeparator: String
    let groupingSeparator: GroupingSeparator
    let minusSign: String
    let primaryGroupingSize: GroupingSize
    let secondaryGroupingSize: GroupingSize
    // How this locale arranges a currency symbol, a sign and the digits, from its CLDR pattern.
    let pattern: MoneyFormatPattern
    // The same, for a currency written out in words, per plural category, from CLDR's unit patterns.
    // A name never takes accounting parentheses, so this carries no accounting form of its own.
    let fullNamePattern: FullNameLayout
    // The space between an ISO code (or a code used as a fallback symbol) and the digits.
    let isoCodeSpacing: String
    // The gap between the amount and a currency's full name.
    let fullNameSpacing: Spacing
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
