public extension Sequence where Element == Money {
    /// Returns the least amount, or `nil` if there are none.
    ///
    /// Every amount's currency is checked, including those after the least.
    ///
    /// ```swift
    /// let quotes = [Money(minorUnits: 4_99, currency: .gbp), Money(minorUnits: 3_49, currency: .gbp)]
    /// try quotes.min()   // £3.49
    /// ```
    ///
    /// - Returns: The least amount, or `nil` if the sequence is empty.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the amounts are not all in the same
    ///   currency. `lhs` is the first amount's currency, and `rhs` is the currency of the first
    ///   amount that differs from it.
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    @warn_unqualified_access
    func min() throws(MoneyError) -> Money? {
        var iterator = makeIterator()
        guard let first = iterator.next() else {
            return nil
        }

        let currency = first.storage
        var least = first.minorUnits
        while let amount = iterator.next() {
            try AnyCurrency.requireMatch(currency, amount.storage)
            least = Swift.min(least, amount.minorUnits)
        }
        return Money(unchecked: least, storage: currency)
    }

    /// Returns the greatest amount, or `nil` if there are none.
    ///
    /// Every amount's currency is checked, including those after the greatest.
    ///
    /// ```swift
    /// let prices = [Money(minorUnits: 4_99, currency: .gbp), Money(minorUnits: 3_49, currency: .gbp)]
    /// try prices.max()   // £4.99
    /// ```
    ///
    /// - Returns: The greatest amount, or `nil` if the sequence is empty.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the amounts are not all in the same
    ///   currency. `lhs` is the first amount's currency, and `rhs` is the currency of the first
    ///   amount that differs from it.
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    @warn_unqualified_access
    func max() throws(MoneyError) -> Money? {
        var iterator = makeIterator()
        guard let first = iterator.next() else {
            return nil
        }

        let currency = first.storage
        var greatest = first.minorUnits
        while let amount = iterator.next() {
            try AnyCurrency.requireMatch(currency, amount.storage)
            greatest = Swift.max(greatest, amount.minorUnits)
        }
        return Money(unchecked: greatest, storage: currency)
    }
}
