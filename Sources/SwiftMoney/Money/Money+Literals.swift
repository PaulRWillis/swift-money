// MARK: - ExpressibleByIntegerLiteral

extension Money: ExpressibleByIntegerLiteral {
    /// Creates a value from an integer literal where the integer lliteral
    /// represents the mone value in minor units.
    ///
    /// Enables natural integer literal syntax:
    /// ```swift
    /// let price: Money<GBP> = 42 // 42p, NOT £42.00
    /// ```
    ///
    /// - Parameter value: The integer literal value.
    @inlinable
    public init(integerLiteral value: Int64) {
        self.init(minorUnits: value)
    }
}
