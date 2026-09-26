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
