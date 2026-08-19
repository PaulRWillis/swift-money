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
    /// let gbp = GBP(minorUnits: 4_99)   // £4.99
    /// let jpy = JPY(minorUnits: 4_99)   // ¥499
    /// ```
    ///
    /// Takes any integer type, so the width an amount is stored in stays out of this signature and
    /// can change without breaking callers.
    ///
    /// - Parameter minorUnits: The number of the currency's smallest units.
    /// - Precondition: `minorUnits` is representable. A value beyond ``min`` or ``max`` traps, as
    ///   arithmetic that leaves the range does.
    @inlinable
    public init(minorUnits: some BinaryInteger) {
        guard let representable = Int64(exactly: minorUnits) else {
            preconditionFailure("Not a representable amount: \(minorUnits)")
        }

        self.minorUnits = representable
    }

    // No range check: for call sites holding a value this type computed, and so already knows is
    // representable. Public construction validates; internal arithmetic must not pay for it.
    @usableFromInline
    init(
        unchecked minorUnits: Int64
    ) {
        self.minorUnits = minorUnits
    }
}

// MARK: - Min/Max

public extension MoneyOf {
    /// The smallest representable monetary amount.
    static var min: Self {
        Self(unchecked: Int64.min)
    }

    /// The largest representable monetary amount.
    static var max: Self {
        Self(unchecked: Int64.max)
    }
}

// MARK: - AdditiveArithmetic

extension MoneyOf: AdditiveArithmetic {
    public static var zero: Self {
        Self(unchecked: Int64.zero)
    }

    // MARK: - Addition

    /// Returns the sum of two values.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// let a = GBP(minorUnits: 1_05) // £1.05
    /// let b = GBP(minorUnits: 3_25) // £3.25
    /// let sum = a + b  // 430 (£4.30)
    /// ```
    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(unchecked: lhs.minorUnits + rhs.minorUnits)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// var total = GBP(minorUnits: 1_00) // £1.00
    /// total += GBP(minorUnits: 5)
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
    /// let a = GBP(minorUnits: 10_50) // £10.50
    /// let b = GBP(minorUnits: 3_25) // £3.25
    /// let diff = a - b  // 725 (£7.25)
    /// ```
    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(unchecked: lhs.minorUnits - rhs.minorUnits)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// Traps on overflow.
    ///
    /// ```swift
    /// var balance = GBP(minorUnits: 100_00) // £100.00
    /// balance -= GBP(minorUnits: 25_50) // £25.50
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
    @inlinable
    public static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        Self(unchecked: lhs.minorUnits * Int64(rhs))
    }

    /// Returns the result of multiplying an `Int` scalar by a `MoneyOf` value.
    ///
    /// Traps on overflow.
    @inlinable
    public static func * (lhs: some BinaryInteger, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Multiplies a `MoneyOf` value by an `Int` scalar in place.
    ///
    /// Traps on overflow.
    @inlinable
    public static func *= (lhs: inout Self, rhs: some BinaryInteger) {
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
    /// GBP(minorUnits: 9_99).scaled(by: Ratio(1, 3))    // .exact(£3.33)
    /// GBP(minorUnits: 10_00).scaled(by: Ratio(1, 3))   // .inexact(£3.33, remainder: 1/3)
    /// ```
    ///
    /// - Parameter ratio: The fraction to scale by.
    /// - Precondition: The result is representable. Scaling past ``min`` or ``max`` traps.
    public func scaled(
        by ratio: Ratio
    ) -> Scaled<Self> {
        guard let scaled = SwiftMoney.scaled(minorUnits, by: ratio) else {
            preconditionFailure("Scaling by \(ratio) is not representable")
        }

        // Switched here rather than through a shared `map`, which cost fifteen times as much: a
        // closure taken by a generic method, called from a generic type that is not inlinable, cannot
        // be specialized away.
        switch scaled {
        case let .exact(whole):
            return .exact(Self(unchecked: whole))
        case let .inexact(whole, remainder):
            return .inexact(Self(unchecked: whole), remainder: remainder)
        }
    }

    /// Returns this monetary amount scaled by a fraction and resolved to a whole unit.
    ///
    /// Use this where the caller already knows how a leftover part should be settled. Use
    /// ``scaled(by:)`` to find out whether there was one.
    ///
    /// ```swift
    /// GBP(minorUnits: 10).scaled(by: Ratio(1, 4), rounding: .toNearestOrEven)   // 2p, from 2.5p
    /// GBP(minorUnits: 10).scaled(by: Ratio(1, 4), rounding: .up)           // 3p
    /// ```
    ///
    /// - Parameters:
    ///   - ratio: The fraction to scale by.
    ///   - rule: How to resolve part of a unit left over.
    /// - Precondition: The result is representable. Scaling past ``min`` or ``max`` traps, including
    ///   where only the rounding step passes them.
    public func scaled(
        by ratio: Ratio,
        rounding rule: RoundingRule
    ) -> Self {
        guard
            let scaled = SwiftMoney.scaled(minorUnits, by: ratio),
            let rounded = scaled.rounded(rule)
        else {
            preconditionFailure("Scaling by \(ratio) is not representable")
        }

        return Self(unchecked: rounded)
    }
}

// MARK: - Split

extension MoneyOf {
    /// Returns this monetary amount split into `parts`, as evenly as possible.
    ///
    /// ```swift
    /// GBP(minorUnits: 100_00).split(into: 3)   // one part of £33.34, two of £33.33
    /// ```
    @inlinable
    public func split(
        into parts: PartCount
    ) -> Split<Self> {
        SwiftMoney.split(minorUnits, into: parts)
            .map { Self(unchecked: $0) }
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
    /// GBP(minorUnits: 9_99).isMultiple(of: GBP(minorUnits: 3_33))   // true  — exactly three times
    /// GBP(minorUnits: 6_01).isMultiple(of: GBP(minorUnits: 2_00))   // false — a penny left over
    /// ```
    ///
    /// Zero is a multiple of every amount, including zero. No other amount is a multiple of zero.
    ///
    /// - Parameter other: The amount to measure against.
    public func isMultiple(of other: Self) -> Bool {
        self.minorUnits.isMultiple(of: other.minorUnits)
    }
}
