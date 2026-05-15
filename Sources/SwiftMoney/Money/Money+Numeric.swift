// MARK: - Magnitude & Negation

extension Money {
    /// The magnitude type.
    public typealias Magnitude = Money

    /// The absolute value of this instance.
    ///
    /// Traps when called on `.min` (`Int64.min`), whose negation overflows,
    /// matching Swift's `Int` behavior.
    ///
    /// ```swift
    /// let v = Money("-5.0")!
    /// v.magnitude  // 5.0
    /// ```
    /// - Precondition: The value must not be `.min`.
    @inlinable
    public var magnitude: Magnitude {
        precondition(_minorUnits != .min, "Money.magnitude: negating .min overflows Int64")
        return Money(minorUnits: abs(_minorUnits))
    }

    /// Returns the additive inverse of this value.
    ///
    /// Traps when called on `.min` (`Int64.min`), whose negation overflows,
    /// matching Swift's `Int` behavior.
    ///
    /// ```swift
    /// let price = Money<GBP>(4250) // £42.50
    /// let neg = -price  // -£42.50
    /// ```
    ///
    /// - Parameter operand: The value to negate.
    /// - Returns: The negated value.
    /// - Precondition: The operand must not be `.min`.
    @inlinable
    public prefix static func - (operand: Money) -> Money {
        var copy = operand
        copy.negate()
        return copy
    }

    /// Replaces this value with its additive inverse.
    ///
    /// Traps when called on `.min` (`Int64.min`), whose negation overflows,
    /// matching Swift's `Int` behavior.
    ///
    /// ```swift
    /// var price = Money<GBP>(4250) // £42.50
    /// price.negate()
    /// // price is now -4250 (-£42.50)
    /// ```
    /// - Precondition: The value must not be `.min`.
    @inlinable
    public mutating func negate() {
        precondition(_minorUnits != .min, "Money.negate(): negating .min overflows Int64")
        _minorUnits = -_minorUnits
    }
}
