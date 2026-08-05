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

    private let minorUnits: Int

    /// Creates a monetary amount from a whole number of the currency's smallest
    /// (minor) units.
    ///
    /// ```swift
    /// let price = Money(4_99, currency: .gbp)   // £4.99
    /// ```
    ///
    /// - Parameter currency: The currency to denominate the amount in. Two amounts combine only when
    ///   their currencies are equal, and that includes the quantization — `XYZ` at 100 and `XYZ` at 1
    ///   are different currencies.
    public init(
        _ minorUnits: Int,
        currency: Currency,
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

        return Money(result, currency: self.currency)
    }

    /// Returns the sum of two values.
    ///
    /// ```swift
    /// let a = Money(1_05, currency: .gbp) // £1.05
    /// let b = Money(3_25, currency: .gbp) // £3.25
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

        return Money(result, currency: self.currency)
    }

    /// Returns the difference of two values.
    ///
    /// ```swift
    /// let a = Money(10_50, currency: .gbp) // £10.50
    /// let b = Money(3_25, currency: .gbp) // £3.25
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
    private func multiplied(by factor: Int) throws(MoneyError) -> Self {
        let (result, didOverflow) = self.minorUnits.multipliedReportingOverflow(by: factor)

        guard !didOverflow else {
            throw .overflow
        }

        return Money(result, currency: self.currency)
    }

    /// Returns this amount scaled by a whole number.
    ///
    /// - Throws: ``MoneyError/overflow`` if the product is not representable.
    public static func * (lhs: Self, rhs: Int) throws(MoneyError) -> Self {
        try lhs.multiplied(by: rhs)
    }

    /// Returns this amount scaled by a whole number.
    ///
    /// - Throws: ``MoneyError/overflow`` if the product is not representable.
    public static func * (lhs: Int, rhs: Self) throws(MoneyError) -> Self {
        try rhs.multiplied(by: lhs)
    }

    /// Scales this amount by a whole number in place.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/overflow`` if the product is not representable.
    public static func *= (lhs: inout Self, rhs: Int) throws(MoneyError) {
        lhs = try lhs * rhs
    }
}

// MARK: - isMultiple(of:)

extension Money {
    /// Returns whether this amount is a whole multiple of another.
    ///
    /// ```swift
    /// try Money(9_99, currency: .gbp).isMultiple(of: Money(3_33, currency: .gbp))   // true
    /// try Money(6_01, currency: .gbp).isMultiple(of: Money(2_00, currency: .gbp))   // false
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
    /// try Money(9_99, currency: .gbp).scaled(by: Ratio(1, 3))    // .exact(£3.33)
    /// try Money(10_00, currency: .gbp).scaled(by: Ratio(1, 3))   // .inexact(£3.33, remainder: 1/3)
    /// ```
    ///
    /// - Parameter ratio: The fraction to scale by.
    /// - Throws: ``MoneyError/overflow`` if the result is not representable.
    public func scaled(
        by ratio: Ratio
    ) throws(MoneyError) -> Scaled<Self> {
        guard let scaled = POCMoney.scaled(minorUnits, by: ratio) else {
            throw .overflow
        }

        return scaled.map { Money($0, currency: currency) }
    }

    /// Returns this monetary amount scaled by a fraction and resolved to a whole unit.
    ///
    /// Use this where the caller already knows how a leftover part should be settled. Use
    /// ``scaled(by:)`` to find out whether there was one.
    ///
    /// ```swift
    /// let price = Money(10, currency: .gbp)
    /// try price.scaled(by: Ratio(1, 4), rounding: .toNearestOrEven)   // 2p, from 2.5p
    /// try price.scaled(by: Ratio(1, 4), rounding: .ceiling)           // 3p
    /// ```
    ///
    /// - Parameters:
    ///   - ratio: The fraction to scale by.
    ///   - mode: How to resolve part of a unit left over.
    /// - Throws: ``MoneyError/overflow`` if the result is not representable, including where only the
    ///   rounding step makes it so.
    public func scaled(
        by ratio: Ratio,
        rounding mode: RoundingMode
    ) throws(MoneyError) -> Self {
        guard
            let scaled = POCMoney.scaled(minorUnits, by: ratio),
            let rounded = scaled.rounded(mode)
        else {
            throw .overflow
        }

        return Money(rounded, currency: currency)
    }
}

// MARK: - Split

extension Money {
    /// Returns this monetary amount split into `parts`, as evenly as possible.
    ///
    /// ```swift
    /// Money(100_00, currency: .gbp).split(into: 3)   // one part of £33.34, two of £33.33
    /// ```
    public func split(
        into parts: PartCount
    ) -> Split<Self> {
        POCMoney.split(minorUnits, into: parts)
            .map { Money($0, currency: currency) }
    }
}

#warning("TODO: Subunit pricing")
#warning("TODO: Currency conversion")
#warning("TODO: Minor units as MinorUnit")
