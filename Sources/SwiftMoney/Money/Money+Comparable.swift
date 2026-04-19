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
