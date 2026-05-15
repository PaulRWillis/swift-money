// MARK: - Magnitude & Negation

extension Money {
    /// The magnitude type.
    public typealias Magnitude = Money

    /// The absolute value of this instance.
    ///
    /// Safe for all representable values because `MinorUnit` excludes
    /// `Int64.min`, whose negation would overflow.
    ///
    /// ```swift
    /// let v = Money("-5.0")!
    /// v.magnitude  // 5.0
    /// ```
    @inlinable
    public var magnitude: Magnitude {
        let absValue = abs(Int64(_minorUnits))
        guard let minorUnit = MinorUnit(exactly: absValue) else {
            preconditionFailure("Money.magnitude: abs produced unrepresentable value")
        }
        return Money(minorUnits: minorUnit)
    }

    /// Returns the additive inverse of this value.
    ///
    /// Safe for all representable values because `MinorUnit` excludes
    /// `Int64.min`, whose negation would overflow.
    ///
    /// ```swift
    /// let price = Money<GBP>(4250) // £42.50
    /// let neg = -price  // -£42.50
    /// ```
    ///
    /// - Parameter operand: The value to negate.
    /// - Returns: The negated value.
    @inlinable
    public prefix static func - (operand: Money) -> Money {
        var copy = operand
        copy.negate()
        return copy
    }

    /// Replaces this value with its additive inverse.
    ///
    /// Safe for all representable values because `MinorUnit` excludes
    /// `Int64.min`, whose negation would overflow.
    ///
    /// ```swift
    /// var price = Money<GBP>(4250) // £42.50
    /// price.negate()
    /// // price is now -4250 (-£42.50)
    /// ```
    @inlinable
    public mutating func negate() {
        let negated = -Int64(_minorUnits)
        guard let minorUnit = MinorUnit(exactly: negated) else {
            preconditionFailure("Money.negate: negation produced unrepresentable value")
        }
        _minorUnits = minorUnit
    }
}
