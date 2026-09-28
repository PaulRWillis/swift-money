// A currency's symbol and narrow symbol in one locale, each with the spacing CLDR resolves for it, and
// whether a letter touches the number (Axis B of the accounting-currency-side design). Only currencies
// whose symbol differs from their code are stored; the rest fall back to the code.
package struct CurrencyDisplay: Equatable, Hashable, Sendable {
    package let standardSymbol: String
    package let standardSpacing: Spacing
    package let standardForm: SymbolForm
    package let narrowSymbol: String
    package let narrowSpacing: Spacing
    package let narrowForm: SymbolForm

    package init(
        standardSymbol: String,
        standardSpacing: Spacing,
        standardForm: SymbolForm,
        narrowSymbol: String,
        narrowSpacing: Spacing,
        narrowForm: SymbolForm
    ) {
        self.standardSymbol = standardSymbol
        self.standardSpacing = standardSpacing
        self.standardForm = standardForm
        self.narrowSymbol = narrowSymbol
        self.narrowSpacing = narrowSpacing
        self.narrowForm = narrowForm
    }
}
