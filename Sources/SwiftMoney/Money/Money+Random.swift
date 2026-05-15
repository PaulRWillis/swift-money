// MARK: - Random

extension Money {

    /// Returns a random value within the specified closed range.
    ///
    /// - Parameter range: The range in which to create a random value.
    /// - Returns: A random value within the bounds of `range`.
    @inlinable
    public static func random(in range: ClosedRange<Money>) -> Money {
        let raw = Int64.random(
            in: Int64(range.lowerBound._minorUnits)...Int64(range.upperBound._minorUnits)
        )
        guard let minorUnit = MinorUnit(exactly: raw) else {
            preconditionFailure("Money.random produced unrepresentable value")
        }
        return Money(minorUnits: minorUnit)
    }

    /// Returns a random value within the specified closed range, using the given
    /// generator as a source for randomness.
    ///
    /// - Parameters:
    ///   - range: The range in which to create a random value.
    ///   - generator: The random number generator to use when creating the
    ///     new random value.
    /// - Returns: A random value within the bounds of `range`.
    @inlinable
    public static func random<T: RandomNumberGenerator>(
        in range: ClosedRange<Money>,
        using generator: inout T
    ) -> Money {
        let raw = Int64.random(
            in: Int64(range.lowerBound._minorUnits)...Int64(range.upperBound._minorUnits),
            using: &generator
        )
        guard let minorUnit = MinorUnit(exactly: raw) else {
            preconditionFailure("Money.random produced unrepresentable value")
        }
        return Money(minorUnits: minorUnit)
    }

    /// Returns a random value within the specified half-open range.
    ///
    /// - Parameter range: The range in which to create a random value.
    ///   `range` must not be empty.
    /// - Returns: A random value within the bounds of `range`.
    /// - Precondition: `range` must not be empty.
    @inlinable
    public static func random(in range: Range<Money>) -> Money {
        let raw = Int64.random(
            in: Int64(range.lowerBound._minorUnits)..<Int64(range.upperBound._minorUnits)
        )
        guard let minorUnit = MinorUnit(exactly: raw) else {
            preconditionFailure("Money.random produced unrepresentable value")
        }
        return Money(minorUnits: minorUnit)
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
    /// - Precondition: `range` must not be empty.
    @inlinable
    public static func random<T: RandomNumberGenerator>(
        in range: Range<Money>,
        using generator: inout T
    ) -> Money {
        let raw = Int64.random(
            in: Int64(range.lowerBound._minorUnits)..<Int64(range.upperBound._minorUnits),
            using: &generator
        )
        guard let minorUnit = MinorUnit(exactly: raw) else {
            preconditionFailure("Money.random produced unrepresentable value")
        }
        return Money(minorUnits: minorUnit)
    }
}
