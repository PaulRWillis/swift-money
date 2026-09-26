// Why a coded string is not an amount. Reported rather than collapsed into `nil`, because the three
// have three remedies, and telling a caller to write fewer decimals when their currency is the
// problem sends them the wrong way.
enum CodedStringError: Error, Equatable {
    // Nothing named a currency, and this representation cannot supply one.
    case unnamedCurrency

    // The code names a currency this representation cannot be.
    case unresolvedCurrency(CurrencyCode)

    // The digits are not a whole number of the smallest units of the currency they are in.
    case inexactAmount(Currency)
}
