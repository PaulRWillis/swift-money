import SwiftMoneyCore

// The locale-dependent pieces the generated CLDR tables carry, composed into a `MoneyFormat` at lookup
// time. Internal — the public surface is `MoneyLocalization.moneyFormat(for:locale:presentation:)`.
struct LocaleNumberFormat {
    let decimalSeparator: String
    let groupingSeparator: GroupingSeparator
    let minusSign: String
    let primaryGroupingSize: GroupingSize
    let secondaryGroupingSize: GroupingSize
    let placement: MoneyFormat.SymbolPlacement
    // The space between an ISO code (or a code used as a fallback symbol) and the digits.
    let isoCodeSpacing: String
    // How this locale's accounting form marks a negative: parentheses (en/ja) or a minus (de).
    let accountingNegative: MoneyFormat.AccountingNegative
}

// A currency's symbol and narrow symbol in one locale, each with the spacing CLDR resolves for it. Only
// currencies whose symbol differs from their code are stored; the rest fall back to the code.
struct CurrencyDisplay {
    let standardSymbol: String
    let standardSpacing: String
    let narrowSymbol: String
    let narrowSpacing: String
}
