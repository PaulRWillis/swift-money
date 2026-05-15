// MARK: - Equatable

extension AnyMoney: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Two `AnyMoney` values are equal when both their ``currencyCode`` and
    /// ``minorUnits`` match.
    ///
    /// ```swift
    /// Money<GBP>(minorUnits: 500).erased == Money<GBP>(minorUnits: 500).erased  // true
    /// Money<GBP>(minorUnits: 500).erased == Money<EUR>(minorUnits: 500).erased  // false
    /// ```
    ///
    /// - Complexity: O(1)
    public static func == (lhs: AnyMoney, rhs: AnyMoney) -> Bool {
        lhs.currencyCode == rhs.currencyCode && lhs.minorUnits == rhs.minorUnits
    }
}

// MARK: - Hashable

extension AnyMoney: Hashable {
    /// Hashes the currency code and minor units into the given hasher.
    ///
    /// Two values that compare equal with `==` always produce the same hash,
    /// satisfying the `Hashable` contract.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of
    ///   this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(currencyCode)
        hasher.combine(minorUnits)
    }
}

// MARK: - Comparable

extension AnyMoney: Comparable {
    /// Returns a Boolean value indicating whether the first value is less than
    /// the second.
    ///
    /// Provides a **total order** across all currencies:
    ///
    /// 1. Values are first ordered by ``currencyCode`` lexicographically.
    /// 2. Within the same currency, values are ordered by ``minorUnits``.
    ///
    /// This means `sorted()` on a `[AnyMoney]` is always deterministic, even
    /// for mixed-currency arrays.
    ///
    /// ```swift
    /// let arr: [AnyMoney] = [
    ///     Money<EUR>(minorUnits: 500).erased,
    ///     Money<GBP>(minorUnits: 100).erased,
    ///     Money<GBP>(minorUnits: 50).erased,
    /// ]
    /// arr.sorted()
    /// // [EUR 500, GBP 50, GBP 100]  ("EUR" < "GBP" lexicographically)
    /// ```
    ///
    /// - Complexity: O(n) where n is the length of the currency code strings,
    ///   O(1) for same-currency comparisons after the string equality check.
    public static func < (lhs: AnyMoney, rhs: AnyMoney) -> Bool {
        if lhs.currencyCode != rhs.currencyCode {
            return lhs.currencyCode < rhs.currencyCode
        }
        return lhs.minorUnits < rhs.minorUnits
    }
}
