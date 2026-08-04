/// Why an arithmetic operation on a monetary amount could not produce a result.
public enum MoneyError: Error, Equatable, Sendable {
    /// The two amounts were in different currencies.
    ///
    /// Both are reported so a caller can say which currencies clashed. The pair is ordered as the
    /// operands were, so `lhs` is the left-hand amount's currency.
    case currencyMismatch(lhs: Currency, rhs: Currency)

    /// The result was too large or too small to represent.
    case overflow
}
