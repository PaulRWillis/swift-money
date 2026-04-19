// MARK: - Magnitude & Negation

extension Money {
    /// The magnitude type.
    public typealias Magnitude = Money

    /// The absolute value of this instance.
    ///
    /// Traps on NaN.
    ///
    /// ```swift
    /// let v = Money("-5.0")!
    /// v.magnitude  // 5.0
    /// ```
    /// - Precondition: The value must not be NaN.
    @inlinable
    public var magnitude: Magnitude {
        precondition(!isNaN, "magnitude called on NaN")
        return Money(minorUnits: abs(_storage))
    }

    /// Returns the additive inverse of this value.
    ///
    /// Traps if the operand is NaN.
    ///
    /// ```swift
    /// let price = Money<GBP>(4250) // £42.50
    /// let neg = -price  // -£42.50
    /// ```
    ///
    /// - Parameter operand: The value to negate.
    /// - Returns: The negated value.
    /// - Precondition: The operand must not be NaN.
    @inlinable
    public prefix static func - (operand: Money) -> Money {
        var copy = operand
        copy.negate()
        return copy
    }

    /// Replaces this value with its additive inverse.
    ///
    /// Traps if the value is NaN.
    ///
    /// ```swift
    /// var price = Money<GBP>(4250) // £42.50
    /// price.negate()
    /// // price is now -4250 (-£42.50)
    /// ```
    /// - Precondition: The value must not be NaN.
    @inlinable
    public mutating func negate() {
        precondition(!isNaN, "NaN in Money negation")
        _storage = -_storage
    }
}
