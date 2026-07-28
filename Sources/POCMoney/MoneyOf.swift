public struct MoneyOf<C: Currency>: Equatable, Hashable, Sendable {

    // MARK: - Private Properties

    private let minorUnits: Int

    // MARK: - Initializers

    public init(
        _ minorUnits: Int
    ) {
        self.minorUnits = minorUnits
    }
}

// MARK: - Min/Max

public extension MoneyOf {
    /// The minimum representable money amount in its currency's minor units.
    static var min: Self {
        Self(Int.min)
    }

    /// The maximum representable money amount in its currency's minor units.
    static var max: Self {
        Self(Int.max)
    }
}

// MARK: - AdditiveArithmetic

/// Conformance to `AdditiveArithmetic`, providing `+`, `-`, `+=`, `-=`, `and `.zero`.
extension MoneyOf: AdditiveArithmetic {
    /// The zero value.
    ///
    /// Returns a value representing zero in the currency's minor units.
    public static var zero: Self {
        Self(.zero)
    }

    // MARK: - Addition

    /// Returns the sum of two values.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// let a = GBP(1_05) // £1.05
    /// let b = GBP(3_25) // £3.25
    /// let sum = a + b  // 430 (£4.30)
    /// ```
    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(lhs.minorUnits + rhs.minorUnits)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// var total = GBP(1_00) // £1.00
    /// total += GBP(5)
    /// // total is now 105 (£1.05)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to add.
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    // MARK: - Subtraction

    /// Returns the difference of two values.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// let a = GBP(10_50) // £10.50
    /// let b = GBP(3_25) // £3.25
    /// let diff = a - b  // 725 (£7.25)
    /// ```
    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(lhs.minorUnits - rhs.minorUnits)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// var balance = GBP(100_00) // £100.00
    /// balance -= GBP(25_50) // £25.50
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
