/// Why an operation on monetary amounts, such as arithmetic or a conversion, could not produce a
/// result.
public enum MoneyError: Error, Equatable, Hashable, Sendable {
    /// Two currencies that must match differ. The error carries both.
    ///
    /// For two amounts, `lhs` is the left-hand amount's currency, or the receiver's for a method,
    /// and `rhs` is the other one's. For a conversion to a typed amount, `lhs` is the currency the
    /// type requires and `rhs` is the given amount's. For a conversion to a typed exchange rate,
    /// `lhs` is the type's currency and `rhs` the rate's, on the side the rate converts from if it
    /// differs and on the side it converts to otherwise.
    ///
    /// ```swift
    /// try GBP(Money(minorUnits: 10_00, currency: .eur))
    /// // throws MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)
    /// ```
    case currencyMismatch(lhs: Currency, rhs: Currency)
}
