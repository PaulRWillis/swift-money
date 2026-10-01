public extension PartialRangeUpTo {
    /// Creates a range of typed amounts from a runtime range, if it is in the bound's currency.
    ///
    /// ```swift
    /// let underLimit = try PartialRangeUpTo<GBP>(..<runtimeLimit)
    /// ```
    ///
    /// - Parameter range: The range whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `range` is in another currency, with
    ///   the bound's currency as `lhs`.
    @inlinable
    init<C: CurrencyType>(_ range: PartialMoneyRangeUpTo) throws(MoneyError) where Bound == MoneyOf<C> {
        try AnyCurrency.requireMatch(C.currency, range.upperBound.storage)

        self.init(MoneyOf<C>(unchecked: range.upperBound.minorUnits, storage: .implied))
    }
}
