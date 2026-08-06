/// A monetary amount in a single currency, fixed at compile time.
///
/// The currency is part of the type, so adding pounds to euros is a compile error rather than a
/// runtime failure. Use ``Money`` when the currency is not known until runtime.
public struct MoneyOf<C: CurrencyType>: Equatable, Hashable, Sendable {
    
    /// The currency this amount is denominated in.
    public var currency: Currency {
        C.currency
    }

    // Internal rather than private so that `split(into:)` can be inlinable.
    @usableFromInline
    let minorUnits: Int64

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
        self.minorUnits = Int64(minorUnits)
    }

    /// Creates a monetary amount from a whole number of the currency's smallest
    /// (minor) units.
    ///
    /// Amounts are held as an `Int64` on every platform, so the range does not vary with the word size.
    public init(
        _ minorUnits: Int64
    ) {
        self.minorUnits = minorUnits
    }
}

// MARK: - Min/Max

public extension MoneyOf {
    /// The smallest representable monetary amount.
    static var min: Self {
        Self(Int64.min)
    }

    /// The largest representable monetary amount.
    static var max: Self {
        Self(Int64.max)
    }
}

// MARK: - AdditiveArithmetic

extension MoneyOf: AdditiveArithmetic {
    public static var zero: Self {
        Self(Int64.zero)
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
        Self(lhs.minorUnits * Int64(rhs))
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

// MARK: - Fractional Scaling

extension MoneyOf {
    /// Returns this monetary amount scaled by a fraction.
    ///
    /// A monetary amount is always a whole number of the currency's smallest unit, so a fraction that
    /// does not divide exactly leaves part of a unit for the caller to resolve.
    ///
    /// ```swift
    /// GBP(9_99).scaled(by: Ratio(1, 3))    // .exact(£3.33)
    /// GBP(10_00).scaled(by: Ratio(1, 3))   // .inexact(£3.33, remainder: 1/3)
    /// ```
    ///
    /// - Parameter ratio: The fraction to scale by.
    /// - Precondition: The result is representable. Scaling past ``min`` or ``max`` traps.
    public func scaled(
        by ratio: Ratio
    ) -> Scaled<Self> {
        guard let scaled = POCMoney.scaled(minorUnits, by: ratio) else {
            preconditionFailure("Scaling by \(ratio) is not representable")
        }

        // Switched here rather than through a shared `map`, which cost fifteen times as much: a
        // closure taken by a generic method, called from a generic type that is not inlinable, cannot
        // be specialized away.
        switch scaled {
        case let .exact(whole):
            return .exact(Self(whole))
        case let .inexact(whole, remainder):
            return .inexact(Self(whole), remainder: remainder)
        }
    }

    /// Returns this monetary amount scaled by a fraction and resolved to a whole unit.
    ///
    /// Use this where the caller already knows how a leftover part should be settled. Use
    /// ``scaled(by:)`` to find out whether there was one.
    ///
    /// ```swift
    /// GBP(10).scaled(by: Ratio(1, 4), rounding: .toNearestOrEven)   // 2p, from 2.5p
    /// GBP(10).scaled(by: Ratio(1, 4), rounding: .ceiling)           // 3p
    /// ```
    ///
    /// - Parameters:
    ///   - ratio: The fraction to scale by.
    ///   - mode: How to resolve part of a unit left over.
    /// - Precondition: The result is representable. Scaling past ``min`` or ``max`` traps, including
    ///   where only the rounding step passes them.
    public func scaled(
        by ratio: Ratio,
        rounding mode: RoundingMode
    ) -> Self {
        guard
            let scaled = POCMoney.scaled(minorUnits, by: ratio),
            let rounded = scaled.rounded(mode)
        else {
            preconditionFailure("Scaling by \(ratio) is not representable")
        }

        return Self(rounded)
    }
}

// MARK: - Split

extension MoneyOf {
    /// Returns this monetary amount split into `parts`, as evenly as possible.
    ///
    /// ```swift
    /// GBP(100_00).split(into: 3)   // one part of £33.34, two of £33.33
    /// ```
    @inlinable
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
    /// Returns whether this amount is a whole multiple of another.
    ///
    /// ```swift
    /// GBP(9_99).isMultiple(of: GBP(3_33))   // true  — exactly three times
    /// GBP(6_01).isMultiple(of: GBP(2_00))   // false — a penny left over
    /// ```
    ///
    /// Zero is a multiple of every amount, including zero. No other amount is a multiple of zero.
    ///
    /// - Parameter other: The amount to measure against.
    public func isMultiple(of other: Self) -> Bool {
        self.minorUnits.isMultiple(of: other.minorUnits)
    }
}

// MARK: - Strideable

extension MoneyOf: Strideable {
    /// A count of the currency's smallest (minor) unit.
    public typealias Stride = Int64

    /// Returns the distance from this monetary amount to `other`.
    ///
    /// - Precondition: The distance is representable as a ``Stride``. Amounts further apart than
    ///   that trap.
    public func distance(to other: MoneyOf<C>) -> Int64 {
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
