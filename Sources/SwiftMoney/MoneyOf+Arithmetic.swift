// MARK: - A currency fixed at compile time: arithmetic cannot fail

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

public extension MoneyOf where C: CurrencyType {
    /// Returns the result of multiplying this amount by a whole number.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        Self(unchecked: lhs.minorUnits * Int64(rhs), storage: .implied)
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
    /// Traps on overflow.
    @inlinable
    static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        Self(unchecked: lhs.minorUnits * Int64(rhs), storage: lhs.storage)
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
