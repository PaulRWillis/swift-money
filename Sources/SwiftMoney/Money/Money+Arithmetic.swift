// MARK: - Trapping Arithmetic (default -- matches Swift Int)

extension Money {
    /// Returns the sum of two values.
    ///
    /// Traps if either operand is NaN or if the result overflows,
    /// matching Swift `Int` behavior.
    ///
    /// ```swift
    /// let a: Money<GBP> = 105 // 105p; £1.05
    /// let b: Money<GBP> = 325 // 325p; £3.25
    /// let sum = a + b  // 1375p; £13.75
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The first addend.
    ///   - rhs: The second addend.
    /// - Returns: The sum of `lhs` and `rhs`.
    /// - Precondition: Neither operand may be NaN.
    /// - Precondition: The result must fit in `Int64`.
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        precondition(!lhs.isNaN && !rhs.isNaN, "NaN in Money addition")
        let (result, overflow) = lhs._storage.addingReportingOverflow(rhs._storage)
        precondition(!overflow, "Money addition overflow")
        precondition(result != .min, "Money addition produced NaN sentinel")
        return Self(minorUnits: result)
    }
}

public extension Money {
    static func - (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs._storage - rhs._storage)
    }
}

public extension Money {
    static func * (lhs: Money, rhs: Int64) -> Money {
        Money(minorUnits: lhs._storage * rhs)
    }

    static func * (lhs: Int64, rhs: Money) -> Money {
        Money(minorUnits: lhs * rhs._storage)
    }
}
