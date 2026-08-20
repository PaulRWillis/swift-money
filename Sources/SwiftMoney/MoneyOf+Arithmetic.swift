// Operators are declared per constrained extension with a concrete error type, never generically
// over `C.ArithmeticError`. An associated type in a `throws` clause is a specialisation barrier: it
// measured 3.1ns per operation, about ten times the cost of the operation itself.

// MARK: - A currency fixed at compile time: arithmetic cannot fail

extension MoneyOf: AdditiveArithmetic where C: StaticCurrencyType {
    @inlinable
    public static var zero: Self {
        Self(unchecked: 0, storage: .empty)
    }

    /// Returns the sum of two values.
    ///
    /// Traps on overflow.
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        Self(unchecked: lhs.minorUnits + rhs.minorUnits, storage: .empty)
    }

    /// Returns the difference of two values.
    ///
    /// Traps on overflow.
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        Self(unchecked: lhs.minorUnits - rhs.minorUnits, storage: .empty)
    }
}

extension MoneyOf: Comparable where C: StaticCurrencyType {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.minorUnits < rhs.minorUnits
    }
}

public extension MoneyOf where C: StaticCurrencyType {
    /// Returns the result of multiplying this amount by a whole number.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        Self(unchecked: lhs.minorUnits * Int64(rhs), storage: .empty)
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

// MARK: - A currency only known at runtime: arithmetic can fail

public extension MoneyOf where C == AnyCurrency {
    /// Returns the sum of two values.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the sum is not representable.
    @inlinable
    static func + (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        let storage = try AnyCurrency.combining(lhs.storage, rhs.storage)
        let (result, didOverflow) = lhs.minorUnits.addingReportingOverflow(rhs.minorUnits)

        guard !didOverflow else {
            throw .overflow
        }

        return Self(unchecked: result, storage: storage)
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
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the difference is not representable.
    @inlinable
    static func - (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        let storage = try AnyCurrency.combining(lhs.storage, rhs.storage)
        let (result, didOverflow) = lhs.minorUnits.subtractingReportingOverflow(rhs.minorUnits)

        guard !didOverflow else {
            throw .overflow
        }

        return Self(unchecked: result, storage: storage)
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
    /// - Throws: ``MoneyError/overflow`` if the product is not representable.
    @inlinable
    static func * (lhs: Self, rhs: some BinaryInteger) throws(MoneyError) -> Self {
        let (result, didOverflow) = lhs.minorUnits.multipliedReportingOverflow(by: Int64(rhs))

        guard !didOverflow else {
            throw .overflow
        }

        return Self(unchecked: result, storage: lhs.storage)
    }

    /// Returns this amount scaled by a whole number.
    ///
    /// - Throws: ``MoneyError/overflow`` if the product is not representable.
    @inlinable
    static func * (lhs: some BinaryInteger, rhs: Self) throws(MoneyError) -> Self {
        try rhs * lhs
    }

    /// Scales this amount by a whole number in place.
    ///
    /// `lhs` is left untouched when this throws.
    @inlinable
    static func *= (lhs: inout Self, rhs: some BinaryInteger) throws(MoneyError) {
        lhs = try lhs * rhs
    }

    /// Returns whether this amount is less than another.
    ///
    /// Amounts in different currencies have no order between them, so this throws rather than
    /// answering. That is also why ``Money`` does not conform to `Comparable`: the protocol requires
    /// a total order, and none exists here.
    ///
    /// The standard sorting and extreme-finding algorithms take a throwing closure, so this composes
    /// with them:
    ///
    /// ```swift
    /// let ordered = try prices.sorted { try $0.isLessThan($1) }
    /// let dearest = try prices.max { try $0.isLessThan($1) }
    /// ```
    ///
    /// - Parameter other: The amount to compare against.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    @inlinable
    func isLessThan(_ other: Self) throws(MoneyError) -> Bool {
        _ = try AnyCurrency.combining(storage, other.storage)

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
        _ = try AnyCurrency.combining(storage, other.storage)

        return minorUnits.isMultiple(of: other.minorUnits)
    }
}
