// MARK: - Magnitude & Negation

extension Money {
    /// The magnitude type.
    public typealias Magnitude = Money

    /// The absolute value of this instance.
    ///
    /// Returns the non-negative value. Traps if the value is not representable (e.g. minimum value).
    ///
    /// ```swift
    /// let v = Money("-5.0")!
    /// v.magnitude  // 5.0
    /// ```
    public var magnitude: Magnitude {
        _storage < .zero ? Self(_storage: -_storage) : self
    }

    /// Returns the additive inverse of this value.
    ///
    /// ```swift
    /// let price = Money<GBP>(4250) // £42.50
    /// let neg = -price  // -£42.50
    /// ```
    ///
    /// - Parameter operand: The value to negate.
    /// - Returns: The negated value.
    public prefix static func - (operand: Money) -> Money {
        var copy = operand
        copy.negate()
        return copy
    }

    /// Replaces this value with its additive inverse.
    ///
    /// Traps if the value is not representable (e.g. minimum value).
    ///
    /// ```swift
    /// var price = Money<GBP>(4250) // £42.50
    /// price.negate()
    /// // price is now -4250 (-£42.50)
    /// ```
    public mutating func negate() {
        self = Self(_storage: -_storage)
    }
}
