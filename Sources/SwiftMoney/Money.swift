/// A monetary amount in a currency that is only known at runtime.
///
/// Two amounts can only be combined when their currencies match, which cannot be checked at compile
/// time, so arithmetic throws ``MoneyError`` instead. One `try` covers a whole expression:
///
/// ```swift
/// let total = try (price * 3) + delivery - discount
/// ```
///
/// Prefer ``MoneyOf`` when the currency is known statically.
public struct Money: Equatable, Hashable, Sendable {

    /// The currency this amount is denominated in.
    public let currency: Currency

    // Internal rather than private so that `split(into:)` can be inlinable.
    @usableFromInline
    let minorUnits: Int64

    /// Creates a monetary amount from a whole number of the currency's smallest
    /// (minor) units.
    ///
    /// ```swift
    /// let price = Money(minorUnits: 4_99, currency: .gbp)   // £4.99
    /// ```
    ///
    /// Takes any integer type, so the width an amount is stored in stays out of this signature and
    /// can change without breaking callers.
    ///
    /// - Parameters:
    ///   - minorUnits: The number of the currency's smallest units.
    ///   - currency: The currency to denominate the amount in. Two amounts combine only when their
    ///     currencies are equal, and that includes the quantization: `XYZ` at 100 and `XYZ` at 1 are
    ///     different currencies.
    /// - Precondition: `minorUnits` is representable. A value outside the representable range traps,
    ///   as arithmetic that leaves it does.
    @inlinable
    public init(
        minorUnits: some BinaryInteger,
        currency: Currency
    ) {
        guard let representable = Int64(exactly: minorUnits) else {
            preconditionFailure("Not a representable amount: \(minorUnits)")
        }

        self.minorUnits = representable
        self.currency = currency
    }

    /// Creates a monetary amount from a whole number of the currency's smallest (minor) units, if
    /// the count is representable.
    ///
    /// Use this for a value from outside the program, where an amount too large to hold is bad input
    /// rather than a mistake in the source. The range an amount can hold is deliberately not part of
    /// this API, so a caller cannot check it beforehand.
    ///
    /// ```swift
    /// Money(exactly: fromTheNetwork, currency: .gbp)   // nil rather than a trap
    /// ```
    ///
    /// - Parameters:
    ///   - minorUnits: The number of the currency's smallest units.
    ///   - currency: The currency to denominate the amount in.
    /// - Returns: `nil` if `minorUnits` is outside the range an amount can hold.
    @inlinable
    public init?(
        exactly minorUnits: some BinaryInteger,
        currency: Currency
    ) {
        guard let representable = Int64(exactly: minorUnits) else {
            return nil
        }

        self.minorUnits = representable
        self.currency = currency
    }

    // No range check: for call sites holding a value this type computed, and so already knows is
    // representable. Public construction validates; internal arithmetic must not pay for it.
    @usableFromInline
    init(
        unchecked minorUnits: Int64,
        currency: Currency
    ) {
        self.minorUnits = minorUnits
        self.currency = currency
    }
}

// MARK: - Addition

extension Money {
    private func adding(_ rhs: Self) throws(MoneyError) -> Self {
        guard self.currency == rhs.currency else {
            throw .currencyMismatch(lhs: self.currency, rhs: rhs.currency)
        }

        let (result, didOverflow) = self.minorUnits.addingReportingOverflow(rhs.minorUnits)

        guard !didOverflow else {
            throw .overflow
        }

        return Money(unchecked: result, currency: self.currency)
    }

    /// Returns the sum of two values.
    ///
    /// ```swift
    /// let a = Money(minorUnits: 1_05, currency: .gbp) // £1.05
    /// let b = Money(minorUnits: 3_25, currency: .gbp) // £3.25
    /// let sum = try a + b  // 430 (£4.30)
    /// ```
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the sum is not representable.
    public static func + (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try lhs.adding(rhs)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the sum is not representable.
    public static func += (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs + rhs
    }
}

// MARK: - Subtraction

extension Money {
    private func subtracting(_ rhs: Self) throws(MoneyError) -> Self {
        guard self.currency == rhs.currency else {
            throw .currencyMismatch(lhs: self.currency, rhs: rhs.currency)
        }

        let (result, didOverflow) = self.minorUnits.subtractingReportingOverflow(rhs.minorUnits)

        guard !didOverflow else {
            throw .overflow
        }

        return Money(unchecked: result, currency: self.currency)
    }

    /// Returns the difference of two values.
    ///
    /// ```swift
    /// let a = Money(minorUnits: 10_50, currency: .gbp) // £10.50
    /// let b = Money(minorUnits: 3_25, currency: .gbp) // £3.25
    /// let diff = try a - b  // 725 (£7.25)
    /// ```
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the difference is not representable.
    public static func - (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try lhs.subtracting(rhs)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the difference is not representable.
    public static func -= (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs - rhs
    }
}

// MARK: - Integral Multiplication

extension Money {
    @usableFromInline
    func multiplied(by factor: some BinaryInteger) throws(MoneyError) -> Self {
        let (result, didOverflow) = self.minorUnits.multipliedReportingOverflow(by: Int64(factor))

        guard !didOverflow else {
            throw .overflow
        }

        return Money(unchecked: result, currency: self.currency)
    }

    /// Returns this amount scaled by a whole number.
    ///
    /// - Throws: ``MoneyError/overflow`` if the product is not representable.
    @inlinable
    public static func * (lhs: Self, rhs: some BinaryInteger) throws(MoneyError) -> Self {
        try lhs.multiplied(by: rhs)
    }

    /// Returns this amount scaled by a whole number.
    ///
    /// - Throws: ``MoneyError/overflow`` if the product is not representable.
    @inlinable
    public static func * (lhs: some BinaryInteger, rhs: Self) throws(MoneyError) -> Self {
        try rhs.multiplied(by: lhs)
    }

    /// Scales this amount by a whole number in place.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/overflow`` if the product is not representable.
    @inlinable
    public static func *= (lhs: inout Self, rhs: some BinaryInteger) throws(MoneyError) {
        lhs = try lhs * rhs
    }
}

// MARK: - isMultiple(of:)

extension Money {
    /// Returns whether this amount is a whole multiple of another.
    ///
    /// ```swift
    /// try Money(minorUnits: 9_99, currency: .gbp).isMultiple(of: Money(minorUnits: 3_33, currency: .gbp))   // true
    /// try Money(minorUnits: 6_01, currency: .gbp).isMultiple(of: Money(minorUnits: 2_00, currency: .gbp))   // false
    /// ```
    ///
    /// Zero is a multiple of every amount, including zero. No other amount is a multiple of zero.
    ///
    /// - Parameter other: The amount to measure against.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    public func isMultiple(of other: Self) throws(MoneyError) -> Bool {
        guard self.currency == other.currency else {
            throw .currencyMismatch(lhs: self.currency, rhs: other.currency)
        }

        return self.minorUnits.isMultiple(of: other.minorUnits)
    }
}

// MARK: - Fractional Scaling

extension Money {
    /// Returns this monetary amount scaled by a fraction.
    ///
    /// A monetary amount is always a whole number of the currency's smallest unit, so a fraction that
    /// does not divide exactly leaves part of a unit for the caller to resolve.
    ///
    /// ```swift
    /// try Money(minorUnits: 9_99, currency: .gbp).scaled(by: Ratio(1, 3))    // .exact(£3.33)
    /// try Money(minorUnits: 10_00, currency: .gbp).scaled(by: Ratio(1, 3))   // .inexact(£3.33, remainder: 1/3)
    /// ```
    ///
    /// - Parameter ratio: The fraction to scale by.
    /// - Throws: ``MoneyError/overflow`` if the result is not representable.
    public func scaled(
        by ratio: Ratio
    ) throws(MoneyError) -> Scaled<Self> {
        guard let scaled = SwiftMoney.scaled(minorUnits, by: ratio) else {
            throw .overflow
        }

        switch scaled {
        case let .exact(whole):
            return .exact(Money(unchecked: whole, currency: currency))
        case let .inexact(whole, remainder):
            return .inexact(Money(unchecked: whole, currency: currency), remainder: remainder)
        }
    }

    /// Returns this monetary amount scaled by a fraction and resolved to a whole unit.
    ///
    /// Use this where the caller already knows how a leftover part should be settled. Use
    /// ``scaled(by:)`` to find out whether there was one.
    ///
    /// ```swift
    /// let price = Money(minorUnits: 10, currency: .gbp)
    /// try price.scaled(by: Ratio(1, 4), rounding: .toNearestOrEven)   // 2p, from 2.5p
    /// try price.scaled(by: Ratio(1, 4), rounding: .up)           // 3p
    /// ```
    ///
    /// - Parameters:
    ///   - ratio: The fraction to scale by.
    ///   - rule: How to resolve part of a unit left over.
    /// - Throws: ``MoneyError/overflow`` if the result is not representable, including where only the
    ///   rounding step makes it so.
    public func scaled(
        by ratio: Ratio,
        rounding rule: RoundingRule
    ) throws(MoneyError) -> Self {
        guard
            let scaled = SwiftMoney.scaled(minorUnits, by: ratio),
            let rounded = scaled.rounded(rule)
        else {
            throw .overflow
        }

        return Money(unchecked: rounded, currency: currency)
    }
}

// MARK: - Split

extension Money {
    /// Returns this monetary amount split into `parts`, as evenly as possible.
    ///
    /// ```swift
    /// Money(minorUnits: 100_00, currency: .gbp).split(into: 3)   // one part of £33.34, two of £33.33
    /// ```
    @inlinable
    public func split(
        into parts: PartCount
    ) -> Split<Self> {
        SwiftMoney.split(minorUnits, into: parts)
            .map { Money(unchecked: $0, currency: currency) }
    }
}

#warning("TODO: Subunit pricing")
#warning("TODO: Currency conversion")
#warning("TODO: Minor units as MinorUnit")
