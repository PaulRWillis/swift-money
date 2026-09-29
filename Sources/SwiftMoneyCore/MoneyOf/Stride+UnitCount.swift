public extension MoneyOf.Stride {
    /// A non-zero count of a currency's units, written as an integer literal.
    ///
    /// ```swift
    /// GBP.Stride.majorUnits(5)      // £5
    /// GBP.Stride.minorUnits(-50)    // -50p, stepping downward
    /// ```
    ///
    /// A count can only be a literal, so every count is a constant in the source. A count from outside
    /// the program goes through ``MoneyOf/Stride/init(exactly:)`` instead, which returns `nil` for
    /// zero rather than trapping.
    struct UnitCount: Equatable, Hashable, Sendable {
        @usableFromInline
        let count: Int64
    }
}

extension MoneyOf.Stride.UnitCount: ExpressibleByIntegerLiteral {
    /// Creates a unit count from an integer literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so zero is a mistake in
    /// the source rather than bad input: it traps.
    ///
    /// ```swift
    /// let five: GBP.Stride.UnitCount = 5    // fine
    /// let none: GBP.Stride.UnitCount = 0    // traps
    /// ```
    ///
    /// - Parameter value: The number of units. Negative steps downward.
    /// - Precondition: `value` is not zero.
    @inlinable
    public init(integerLiteral value: Int64) {
        precondition(value != 0, "A stride must not be zero units")

        self.count = value
    }
}

extension MoneyOf.Stride.UnitCount {
    // This count of major units, in minor units of `currency`. For typed strides only: there the
    // currency and the count are both fixed in the source, so a product too large to hold is a
    // mistake in the source and traps, as a zero literal does. A runtime currency is data, so a
    // runtime stride returns `nil` instead.
    @inlinable
    func minorUnits(asMajorUnitsOf currency: Currency) -> Int64 {
        guard let minorUnits = scaledToMinorUnits(count, in: currency) else {
            preconditionFailure("Too many major units for the currency to hold. Count: \(count)")  // coverage:ignore — exit-test trap
        }

        return minorUnits
    }
}
