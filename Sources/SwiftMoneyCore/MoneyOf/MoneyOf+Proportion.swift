public extension MoneyOf where C: CurrencyType {
    /// Returns what fraction of another amount this one is.
    ///
    /// The inverse of ``applying(_:)``: applying the result to the whole and rounding gives this
    /// amount back, within one minor unit.
    ///
    /// ```swift
    /// GBP(minorUnits: 20_00).proportion(of: GBP(minorUnits: 100_00))   // 0.2
    /// ```
    ///
    /// - Parameter whole: The amount to measure against.
    /// - Returns: `nil` if `whole` is zero, which has no parts.
    func proportion(of whole: Self) -> Rate? {
        SwiftMoneyCore.proportion(minorUnits, of: whole.minorUnits)
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
    /// - Returns: `nil` if `whole` is zero, which has no parts.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    func proportion(of whole: Self) throws(MoneyError) -> Rate? {
        try AnyCurrency.requireMatch(storage, whole.storage)

        return SwiftMoneyCore.proportion(minorUnits, of: whole.minorUnits)
    }
}

// The fraction `part / whole`, or `nil` when `whole` is zero. A rate is a decimal, so this is the
// division `applying(_:)` inverts rather than an exact ratio.
func proportion(
    _ part: Int64,
    of whole: Int64
) -> Rate? {
    guard whole != 0 else {
        return nil
    }

    // `Fixed(part) / Fixed(whole)` would widen both sides and divide through the 256-bit path. The result
    // is `part / whole`, which `Fixed(part).divided(by: whole)` reaches with one 128-bit divide —
    // `part × 10¹⁸` fits `Int128` for any `Int64` part — giving the same banker's-rounded value.
    return Rate(Fixed(part).divided(by: whole))
}
