// MARK: - AdditiveArithmetic

/// Conformance to `AdditiveArithmetic`, providing `+`, `-`, `+=`, `-=`, `and `.zero`.
extension Money: AdditiveArithmetic {
    /// The zero value.
    ///
    /// Returns a value representing zero in the currency's minor units.
    public static var zero: Money {
        Money(_storage: .zero)
    }

    /// Returns the sum of two values.
    ///
    /// Traps on overflow or if the result cannot be represented in the valid range for this type.
    ///
    /// ```swift
    /// let a = Money<GBP>(minorUnits: 105) // £1.05
    /// let b = Money<GBP>(minorUnits: 325) // £3.25
    /// let sum = a + b  // 430 (£4.30)
    /// ```
    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(_storage: lhs._storage + rhs._storage)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// var total = Money<GBP>(minorUnits: 100) // £1.00
    /// total += Money<GBP>(minorUnits: 5)
    /// // total is now 105 (£1.05)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to add.
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    /// Returns the difference of two values.
    ///
    /// Traps on overflow or if the result cannot be represented in the valid range for this type.
    ///
    /// ```swift
    /// let a = Money<GBP>(minorUnits: 1050) // £10.50
    /// let b = Money<GBP>(minorUnits: 325) // £3.25
    /// let diff = a - b  // 725 (£7.25)
    /// ```
    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(_storage: lhs._storage - rhs._storage)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// var balance = Money<GBP>(minorUnits: 100_00) // £100.00
    /// balance -= Money<GBP>(minorUnits: 2550) // £25.50
    /// // balance is now 7450 // £74.50
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to subtract.
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }
}

public extension Money {
    /// Returns the result of multiplying a `Money` value by an `Int64` scalar.
    ///
    /// Traps on overflow or if the result cannot be represented in the valid range for this type.
    static func * (lhs: Money, rhs: Int64) -> Money {
        Money(_storage: lhs._storage * rhs)
    }

    /// Returns the result of multiplying an `Int64` scalar by a `Money` value.
    ///
    /// Traps if the result overflows `Int64`.
    ///
    /// - Precondition: The result must fit in `Int64`.
    static func * (lhs: Int64, rhs: Money) -> Money {
        rhs * lhs
    }

    /// Multiplies a `Money` value by an `Int64` scalar in place.
    ///
    /// Traps on overflow.
    static func *= (lhs: inout Money, rhs: Int64) {
        lhs = lhs * rhs
    }
}
