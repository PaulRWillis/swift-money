public extension PartialRangeFrom {
    /// Creates a range of typed amounts from a runtime range, if it is in the bound's currency.
    ///
    /// ```swift
    /// let atLeastMinimum = try PartialRangeFrom<GBP>(runtimeMinimum...)
    /// ```
    ///
    /// - Parameter range: The range whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `range` is in another currency, with
    ///   the bound's currency as `lhs`.
    @inlinable
    init<C: CurrencyType>(_ range: PartialMoneyRangeFrom) throws(MoneyError) where Bound == MoneyOf<C> {
        try AnyCurrency.requireMatch(C.currency, range.lowerBound.storage)

        self.init(MoneyOf<C>(unchecked: range.lowerBound.minorUnits, storage: .implied))
    }
}
