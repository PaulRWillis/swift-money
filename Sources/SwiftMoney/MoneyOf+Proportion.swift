public extension MoneyOf where C: CurrencyType {
    /// Returns what fraction of another amount this one is.
    ///
    /// The inverse of ``scaled(by:)``: scaling the whole by the result gives this amount back.
    ///
    /// ```swift
    /// GBP(minorUnits: 20_00).proportion(of: GBP(minorUnits: 100_00))   // 1/5
    /// ```
    ///
    /// - Parameter whole: The amount to measure against.
    /// - Returns: `nil` if `whole` is zero, which has no parts, or if the fraction has no
    ///   representable numerator.
    @inlinable
    func proportion(of whole: Self) -> Ratio? {
        SwiftMoney.proportion(minorUnits, of: whole.minorUnits)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns what fraction of another amount this one is.
    ///
    /// ```swift
    /// let spent = Money(minorUnits: 20_00, currency: .gbp)
    /// try spent.proportion(of: budget)
    /// ```
    ///
    /// - Parameter whole: The amount to measure against.
    /// - Returns: `nil` if `whole` is zero, which has no parts, or if the fraction has no
    ///   representable numerator.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    @inlinable
    func proportion(of whole: Self) throws(MoneyError) -> Ratio? {
        _ = try AnyCurrency.combining(storage, whole.storage)

        return SwiftMoney.proportion(minorUnits, of: whole.minorUnits)
    }
}
