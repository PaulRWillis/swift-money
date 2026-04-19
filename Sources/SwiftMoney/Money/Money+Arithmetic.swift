// MARK: - Trapping Arithmetic (default -- matches Swift Int)

extension Money {
    /// Returns the sum of two values.
    ///
    /// Traps if either operand is NaN or if the result overflows,
    /// matching Swift `Int` behavior.
    ///
    /// ```swift
    /// let a: Money<GBP> = 105 // £1.05
    /// let b: Money<GBP> = 325 // £3.25
    /// let sum = a + b  // 430 (£4.30)
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

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// Traps on overflow or NaN.
    ///
    /// ```swift
    /// var total: Money<GBP> = 100 // £1.00
    /// total += Money<GBP>(minorUnits: 5)
    /// // total is now 105 (£1.05)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to add.
    @inlinable
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    /// Returns the difference of two values.
    ///
    /// Traps if either operand is NaN or if the result overflows,
    /// matching Swift `Int` behavior.
    ///
    /// ```swift
    /// let a: Money<GBP> = 1050 // £10.50
    /// let b: Money<GBP> = 325 // £3.25
    /// let diff = a - b  // 725 (£7.25)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The minuend.
    ///   - rhs: The subtrahend.
    /// - Returns: The difference of `lhs` and `rhs`.
    /// - Precondition: Neither operand may be NaN.
    /// - Precondition: The result must fit in `Int64` after scaling.
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        precondition(!lhs.isNaN && !rhs.isNaN, "NaN in FixedPointDecimal subtraction")
        let (result, overflow) = lhs._storage.subtractingReportingOverflow(rhs._storage)
        precondition(!overflow, "FixedPointDecimal subtraction overflow")
        precondition(result != .min, "FixedPointDecimal subtraction produced NaN sentinel")
        return Self(minorUnits: result)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// Traps on overflow or NaN.
    ///
    /// ```swift
    /// var balance: Money<GBP> = 100_00 // £100.00
    /// balance -= Money<GBP>(minorUnits: 2550) // £25.50
    /// // balance is now 7450 // £74.50
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to subtract.
    @inlinable
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
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
