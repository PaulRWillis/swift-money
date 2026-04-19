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
}
