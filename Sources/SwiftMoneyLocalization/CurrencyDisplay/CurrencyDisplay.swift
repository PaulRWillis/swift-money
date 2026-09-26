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
