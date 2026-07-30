/// A monetary amount in a single currency, fixed at compile time.
///
/// The currency is part of the type, so adding pounds to euros is a compile error rather than a
/// runtime failure. Use ``Money`` when the currency is not known until runtime.
public struct MoneyOf<C: Currency>: Equatable, Hashable, Sendable {

    // MARK: - Private Properties

    private let minorUnits: Int

    // MARK: - Initializers

    /// Creates a monetary amount from a whole number of the currency's smallest
    /// (minor) units.
    ///
    /// ```swift
    /// let gbp = GBP(4_99)  // £4.99
    /// let jpy = JPY(4_99)     // ¥499
    /// ```
    public init(
        _ minorUnits: Int
    ) {
        self.minorUnits = minorUnits
    }
}

// MARK: - Min/Max

public extension MoneyOf {
    /// The smallest representable monetary amount.
    static var min: Self {
        Self(Int.min)
    }

    /// The largest representable monetary amount.
    static var max: Self {
        Self(Int.max)
    }
}

// MARK: - AdditiveArithmetic

extension MoneyOf: AdditiveArithmetic {
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

// MARK: - Integral Multiplication

extension MoneyOf {
    /// Returns the result of multiplying a `MoneyOf` value by an `Int` scalar.
    ///
    /// Traps on overflow.
    public static func * (lhs: Self, rhs: Int) -> Self {
        Self(lhs.minorUnits * rhs)
    }

    /// Returns the result of multiplying an `Int` scalar by a `MoneyOf` value.
    ///
    /// Traps on overflow.
    public static func * (lhs: Int, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Multiplies a `MoneyOf` value by an `Int` scalar in place.
    ///
    /// Traps on overflow.
    public static func *= (lhs: inout Self, rhs: Int) {
        lhs = lhs * rhs
    }
}

// MARK: - Fractional Multiplication

#warning("TODO")

// MARK: - Split

extension MoneyOf {
    /// Returns this monetary amount split into `parts`, as evenly as possible.
    ///
    /// ```swift
    /// GBP(100_00).split(into: 3)   // one part of £33.34, two of £33.33
    /// ```
    public func split(
        into parts: PartCount
    ) -> Split<Self> {
        POCMoney.split(minorUnits, into: parts)
            .map { Self($0) }
    }
}

// MARK: - Comparable

extension MoneyOf: Comparable {
    public static func < (lhs: MoneyOf<C>, rhs: MoneyOf<C>) -> Bool {
        lhs.minorUnits < rhs.minorUnits
    }
}

// MARK: - isMultipleOf(other:)

extension MoneyOf {
    /// Returns `true` if this value is a multiple of the given value, and `false`
    /// otherwise.
    ///
    /// For two integers *a* and *b*, *a* is a multiple of *b* if there exists a
    /// third integer *q* such that _a = q*b_. For example, *6* is a multiple of
    /// *3* because _6 = 2*3_. Zero is a multiple of everything because _0 = 0*x_
    /// for any integer *x*.
    ///
    /// Two edge cases are worth particular attention:
    /// - `x.isMultiple(of: 0)` is `true` if `x` is zero and `false` otherwise.
    /// - `T.min.isMultiple(of: -1)` is `true` for signed integer `T`, even
    ///   though the quotient `T.min / -1` isn't representable in type `T`.
    ///
    /// - Parameter other: The value to test.
    public func isMultiple(of other: Self) -> Bool {
        self.minorUnits.isMultiple(of: other.minorUnits)
    }
}

// MARK: - Strideable

extension MoneyOf: Strideable {
    /// A count of the currency's smallest (minor) unit.
    public typealias Stride = Int

    /// Returns the distance from this monetary amount to `other`.
    ///
    /// - Precondition: The distance is representable as a ``Stride``. Amounts further apart than
    ///   that trap.
    public func distance(to other: MoneyOf<C>) -> Int {
        other.minorUnits - self.minorUnits
    }

    /// Returns the monetary amount `n` steps from this one.
    ///
    /// Advances in the currency's smallest (minor) unit.
    ///
    /// ```swift
    /// let price = GBP(4_99)   // £4.99
    /// let incr = price.advanced(by: 1)    // £5.00
    /// ```
    ///
    /// - Precondition: The result is representable. Advancing beyond ``min`` or ``max`` traps.
    public func advanced(by n: Stride) -> MoneyOf<C> {
        Self(self.minorUnits + n)
    }
}
