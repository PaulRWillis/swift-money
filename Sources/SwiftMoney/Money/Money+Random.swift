// MARK: - Random

extension Money {

    /// Returns a random value within the specified closed range.
    ///
    /// - Parameter range: The range in which to create a random value.
    /// - Returns: A random value within the bounds of `range`.
    /// - Precondition: Neither bound may be NaN.
    public static func random(in range: ClosedRange<Money>) -> Money {
        precondition(
            !range.lowerBound.isNaN && !range.upperBound.isNaN,
            "Money.random(in:) range must not contain NaN"
        )
        let raw = Int64.random(
            in: range.lowerBound.minorUnits...range.upperBound.minorUnits
        )
        return Money(minorUnits: raw)
    }

    /// Returns a random value within the specified closed range, using the given
    /// generator as a source for randomness.
    ///
    /// - Parameters:
    ///   - range: The range in which to create a random value.
    ///   - generator: The random number generator to use when creating the
    ///     new random value.
    /// - Returns: A random value within the bounds of `range`.
    /// - Precondition: Neither bound may be NaN.
    public static func random<T: RandomNumberGenerator>(
        in range: ClosedRange<Money>,
        using generator: inout T
    ) -> Money {
        precondition(
            !range.lowerBound.isNaN && !range.upperBound.isNaN,
            "Money.random(in:) range must not contain NaN"
        )
        let raw = Int64.random(
            in: range.lowerBound.minorUnits...range.upperBound.minorUnits,
            using: &generator
        )
        return Money(minorUnits: raw)
    }

    /// Returns a random value within the specified half-open range.
    ///
    /// - Parameter range: The range in which to create a random value.
    ///   `range` must not be empty.
    /// - Returns: A random value within the bounds of `range`.
    /// - Precondition: Neither bound may be NaN.
    /// - Precondition: `range` must not be empty.
    public static func random(in range: Range<Money>) -> Money {
        precondition(
            !range.lowerBound.isNaN && !range.upperBound.isNaN,
            "Money.random(in:) range must not contain NaN"
        )
        let raw = Int64.random(
            in: range.lowerBound.minorUnits..<range.upperBound.minorUnits
        )
        return Money(minorUnits: raw)
    }

    /// Returns a random value within the specified half-open range, using the given
    /// generator as a source for randomness.
    ///
    /// - Parameters:
    ///   - range: The range in which to create a random value.
    ///     `range` must not be empty.
    ///   - generator: The random number generator to use when creating the
    ///     new random value.
    /// - Returns: A random value within the bounds of `range`.
    /// - Precondition: Neither bound may be NaN.
    /// - Precondition: `range` must not be empty.
    public static func random<T: RandomNumberGenerator>(
        in range: Range<Money>,
        using generator: inout T
    ) -> Money {
        precondition(
            !range.lowerBound.isNaN && !range.upperBound.isNaN,
            "Money.random(in:) range must not contain NaN"
        )
        let raw = Int64.random(
            in: range.lowerBound.minorUnits..<range.upperBound.minorUnits,
            using: &generator
        )
        return Money(minorUnits: raw)
    }
}
