extension MoneyOf: AdditiveArithmetic where C: CurrencyType {
    @inlinable
    public static var zero: Self {
        Self(unchecked: 0, storage: .implied)
    }

    /// Returns the sum of two values.
    ///
    /// Traps on overflow.
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(unchecked: lhs.minorUnits + rhs.minorUnits, storage: .implied)
    }

    /// Returns the difference of two values.
    ///
    /// Traps on overflow.
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(unchecked: lhs.minorUnits - rhs.minorUnits, storage: .implied)
    }
}

extension MoneyOf: Comparable where C: CurrencyType {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.minorUnits < rhs.minorUnits
    }
}

// Negation, magnitude and the sign queries read one operand and pass its storage through unchanged,
// so no currency can mismatch. One unconditional extension therefore serves both seams, and
// ``Money`` needs no throwing twins.
public extension MoneyOf {
    /// Returns the given amount with its sign flipped.
    ///
    /// Traps when the operand is the smallest representable amount, whose negation is one past
    /// the largest.
    @inlinable
    static prefix func - (operand: Self) -> Self {
        Self(unchecked: -operand.minorUnits, storage: operand.storage)
    }

    /// The amount with a negative sign removed.
    ///
    /// Traps when this amount is the smallest representable amount, whose magnitude is one past
    /// the largest.
    @inlinable
    var magnitude: Self {
        Self(unchecked: abs(minorUnits), storage: storage)
    }

    /// Whether this amount is less than zero.
    @inlinable
    var isNegative: Bool {
        minorUnits < 0
    }

    /// Whether this amount is greater than zero.
    ///
    /// Zero is neither positive nor negative.
    @inlinable
    var isPositive: Bool {
        minorUnits > 0
    }

    /// Whether this amount is zero.
    ///
    /// Holds in any currency, so it answers for a ``Money`` without naming one.
    @inlinable
    var isZero: Bool {
        minorUnits == 0
    }
}

public extension MoneyOf where C: CurrencyType {
    /// Returns the result of multiplying this amount by a whole number.
    ///
    /// Traps on overflow. `Int` always fits `Int64` exactly, so this checks the actual product at
    /// 64-bit width instead of widening through `Int128` — the fast path for the overwhelmingly
    /// common case (a plain number literal or count).
    @inlinable
    static func * (lhs: Self, rhs: Int) -> Self {
        let (product, overflow) = lhs.minorUnits.multipliedReportingOverflow(by: Int64(rhs))
        guard !overflow else {
            preconditionFailure("Scaling by \(rhs) is not representable")
        }
        return Self(unchecked: product, storage: .implied)
    }

    /// Returns the result of multiplying this amount by a whole number.
    ///
    /// Traps on overflow. `Int64` is already the width `minorUnits` is stored in, so this checks the
    /// actual product directly instead of widening through `Int128` — the same fast path as the `Int`
    /// overload above, for callers whose count is explicitly `Int64` rather than the platform `Int`.
    @inlinable
    static func * (lhs: Self, rhs: Int64) -> Self {
        let (product, overflow) = lhs.minorUnits.multipliedReportingOverflow(by: rhs)
        guard !overflow else {
            preconditionFailure("Scaling by \(rhs) is not representable")
        }
        return Self(unchecked: product, storage: .implied)
    }

    /// Returns the result of multiplying this amount by a whole number.
    ///
    /// Traps on overflow. Zero is checked first, before `rhs` is ever converted: zero times any
    /// magnitude is always representable, however wide `rhs`'s own type is (`Int128`, `UInt128`, or
    /// wider still), so this can never trap on a multiplier that doesn't fit some fixed-width box
    /// when the true answer would have been fine.
    @inlinable
    static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        guard lhs.minorUnits != 0 else {
            return Self(unchecked: 0, storage: .implied)
        }

        if let narrow = Int64(exactly: rhs) {
            return lhs * narrow
        }

        // With `lhs` nonzero and `rhs` outside `Int64`, the product's magnitude is at least 2^63,
        // so only -1 × 2^63 fits: `Int64.min`.
        guard lhs.minorUnits == -1, rhs == Int64.min.magnitude else {
            preconditionFailure("Scaling by \(rhs) is not representable")
        }

        return Self(unchecked: .min, storage: .implied)
    }

    /// Returns the result of multiplying a whole number by this amount.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: some BinaryInteger, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Multiplies this amount by a whole number in place.
    ///
    /// Traps on overflow.
    @inlinable
    static func *= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs * rhs
    }

    /// Returns whether this amount is a whole multiple of another.
    ///
    /// ```swift
    /// GBP(minorUnits: 9_99).isMultiple(of: GBP(minorUnits: 3_33))   // true
    /// GBP(minorUnits: 6_01).isMultiple(of: GBP(minorUnits: 2_00))   // false
    /// ```
    ///
    /// Zero is a multiple of every amount, including zero. No other amount is a multiple of zero.
    ///
    /// - Parameter other: The amount to measure against.
    @inlinable
    func isMultiple(of other: Self) -> Bool {
        minorUnits.isMultiple(of: other.minorUnits)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns the sum of two values.
    ///
    /// Traps on overflow.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    @inlinable
    static func + (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try AnyCurrency.requireMatch(lhs.storage, rhs.storage)

        return Self(unchecked: lhs.minorUnits + rhs.minorUnits, storage: lhs.storage)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// `lhs` is left untouched when this throws.
    @inlinable
    static func += (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs + rhs
    }

    /// Returns the difference of two values.
    ///
    /// Traps on overflow.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    @inlinable
    static func - (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try AnyCurrency.requireMatch(lhs.storage, rhs.storage)

        return Self(unchecked: lhs.minorUnits - rhs.minorUnits, storage: lhs.storage)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// `lhs` is left untouched when this throws.
    @inlinable
    static func -= (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs - rhs
    }

    /// Returns this amount scaled by a whole number.
    ///
    /// Traps on overflow. `Int` always fits `Int64` exactly, so this checks the actual product at
    /// 64-bit width instead of widening through `Int128` — the fast path for the overwhelmingly
    /// common case (a plain number literal or count).
    @inlinable
    static func * (lhs: Self, rhs: Int) -> Self {
        let (product, overflow) = lhs.minorUnits.multipliedReportingOverflow(by: Int64(rhs))
        guard !overflow else {
            preconditionFailure("Scaling by \(rhs) is not representable")
        }
        return Self(unchecked: product, storage: lhs.storage)
    }

    /// Returns this amount scaled by a whole number.
    ///
    /// Traps on overflow. `Int64` is already the width `minorUnits` is stored in, so this checks the
    /// actual product directly instead of widening through `Int128` — the same fast path as the `Int`
    /// overload above, for callers whose count is explicitly `Int64` rather than the platform `Int`.
    @inlinable
    static func * (lhs: Self, rhs: Int64) -> Self {
        let (product, overflow) = lhs.minorUnits.multipliedReportingOverflow(by: rhs)
        guard !overflow else {
            preconditionFailure("Scaling by \(rhs) is not representable")
        }
        return Self(unchecked: product, storage: lhs.storage)
    }

    /// Returns this amount scaled by a whole number.
    ///
    /// Traps on overflow. Zero is checked first, before `rhs` is ever converted: zero times any
    /// magnitude is always representable, however wide `rhs`'s own type is (`Int128`, `UInt128`, or
    /// wider still), so this can never trap on a multiplier that doesn't fit some fixed-width box
    /// when the true answer would have been fine.
    @inlinable
    static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        guard lhs.minorUnits != 0 else {
            return Self(unchecked: 0, storage: lhs.storage)
        }

        if let narrow = Int64(exactly: rhs) {
            return lhs * narrow
        }

        guard lhs.minorUnits == -1, rhs == Int64.min.magnitude else {
            preconditionFailure("Scaling by \(rhs) is not representable")
        }

        return Self(unchecked: .min, storage: lhs.storage)
    }

    /// Returns this amount scaled by a whole number.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: some BinaryInteger, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Scales this amount by a whole number in place.
    ///
    /// Traps on overflow.
    @inlinable
    static func *= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs * rhs
    }

    /// Returns whether this amount is less than another.
    ///
    /// Amounts in different currencies have no order between them, so this throws rather than
    /// answering. That is also why ``Money`` does not conform to `Comparable`: the protocol requires
    /// a total order, and none exists here.
    ///
    /// The standard sorting algorithms take a throwing closure, so this composes with them. For the
    /// greatest of two amounts or of a sequence, ``max(_:_:)`` and ``Swift/Sequence/max()`` read more
    /// plainly:
    ///
    /// ```swift
    /// let small = Money(minorUnits: 3_49, currency: .gbp)
    /// let large = Money(minorUnits: 4_99, currency: .gbp)
    /// let prices = [large, small]
    /// try prices.sorted { try $0.isLessThan($1) }   // [£3.49, £4.99]
    /// try prices.max()                              // £4.99
    /// try max(small, large)                         // £4.99
    /// ```
    ///
    /// - Parameter other: The amount to compare against.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    @inlinable
    func isLessThan(_ other: Self) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(storage, other.storage)

        return minorUnits < other.minorUnits
    }

    /// Returns whether this amount is a whole multiple of another.
    ///
    /// Zero is a multiple of every amount, including zero. No other amount is a multiple of zero.
    ///
    /// - Parameter other: The amount to measure against.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    @inlinable
    func isMultiple(of other: Self) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(storage, other.storage)

        return minorUnits.isMultiple(of: other.minorUnits)
    }
}
