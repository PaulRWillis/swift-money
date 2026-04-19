// MARK: - Equatable

extension Money: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// NaN compares equal to itself, using sentinel semantics (not IEEE 754).
    /// This provides a strict total order, enabling predictable use in
    /// `Set`, `Dictionary`, and `sort()` without the pitfalls of IEEE 754
    /// NaN inequality.
    ///
    /// ```swift
    /// let a: Money<GBP> = 105
    /// let b: Money<GBP> = 105
    /// a == b  // true
    ///
    /// Money<GBP>.nan == .nan  // true (sentinel semantics)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if the two values have the same raw storage.
    /// - Complexity: O(1) -- single integer comparison.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._storage == rhs._storage
    }
}

// MARK: - Comparable

extension Money: Comparable {
    /// Returns a Boolean value indicating whether the first value is less than
    /// the second.
    ///
    /// NaN (`Int64.min`) compares less than all non-NaN values, providing
    /// a strict total order suitable for sorting.
    ///
    /// ```swift
    /// let a: Money<GBP> = 20
    /// let b: Money<GBP> = 10
    /// a < b  // true
    ///
    /// Money<GBP>.nan < a  // true (NaN sorts before all values)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - Returns: `true` if `lhs` is strictly less than `rhs`.
    /// - Complexity: O(1) -- single integer comparison.
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs._storage < rhs._storage
    }
}

// MARK: - Hashable

extension Money: Hashable {
    /// Hashes the raw storage value into the given hasher.
    ///
    /// Two values that compare equal with `==` always produce the same hash,
    /// satisfying the `Hashable` contract.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_storage)
    }
}

// MARK: - minimum / maximum

extension Money {
    /// Returns the lesser of the two given values.
    ///
    /// Unlike the stdlib free function `min(_:_:)` which uses `<` comparison
    /// (where NaN sorts below all values), this method traps if either
    /// argument is NaN, ensuring both operands are meaningful values.
    ///
    /// ```swift
    /// Money<GBP>.minimum(3, 5)     // 3
    /// Money<GBP>.minimum(-1, 1)    // -1
    /// Money<GBP>.minimum(.nan, 5)  // traps
    /// ```
    ///
    /// - Parameters:
    ///   - x: A value to compare.
    ///   - y: Another value to compare.
    /// - Returns: The lesser of `x` and `y`.
    /// - Precondition: Neither argument may be NaN.
    /// - Complexity: O(1) -- single integer comparison after NaN checks.
    @inlinable
    public static func minimum(_ x: Self, _ y: Self) -> Self {
        precondition(!x.isNaN && !y.isNaN, "NaN in Money minimum")
        return x._storage <= y._storage ? x : y
    }

    /// Returns the greater of the two given values.
    ///
    /// Unlike the stdlib free function `max(_:_:)` which uses `<` comparison
    /// (where NaN sorts below all values), this method traps if either
    /// argument is NaN, ensuring both operands are meaningful values.
    ///
    /// ```swift
    /// Money.maximum(3, 5)     // 5
    /// Money.maximum(-1, 1)    // 1
    /// Money.maximum(.nan, 5)  // traps
    /// ```
    ///
    /// - Parameters:
    ///   - x: A value to compare.
    ///   - y: Another value to compare.
    /// - Returns: The greater of `x` and `y`.
    /// - Precondition: Neither argument may be NaN.
    /// - Complexity: O(1) -- single integer comparison after NaN checks.
    @inlinable
    public static func maximum(_ x: Self, _ y: Self) -> Self {
        precondition(!x.isNaN && !y.isNaN, "NaN in Money maximum")
        return x._storage >= y._storage ? x : y
    }
}
