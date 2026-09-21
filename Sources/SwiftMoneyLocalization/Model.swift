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
    // The same, for a currency written out in words. Its negatives keep the minus sign, since a
    // locale's accounting form belongs to the pattern that writes a symbol.
    let fullNamePattern: MoneyFormatPattern
    // The space between an ISO code (or a code used as a fallback symbol) and the digits.
    let isoCodeSpacing: String
    // The gap between the amount and a currency's full name.
    let fullNameSpacing: Spacing
}

// A currency's symbol and narrow symbol in one locale, each with the spacing CLDR resolves for it. Only
// currencies whose symbol differs from their code are stored; the rest fall back to the code.
struct CurrencyDisplay {
    let standardSymbol: String
    let standardSpacing: String
    let narrowSymbol: String
    let narrowSpacing: String
}
