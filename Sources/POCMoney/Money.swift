/// A monetary amount in a currency that is only known at runtime.
///
/// Two amounts can only be combined when their currencies match, which cannot be checked at compile
/// time, so arithmetic produces an `Optional` and yields `nil` when they differ. The same operators
/// are provided on `Money?` so results still chain:
///
/// ```swift
/// let total = a + b + c   // Money?
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
    func adding(_ rhs: Self) -> Self? {
        guard self.currency == rhs.currency else { return nil }

        let (result, didOverflow) = self.minorUnits.addingReportingOverflow(rhs.minorUnits)

        guard !didOverflow else { return nil }

        return Money(
            result,
            currency: self.currency,
        )
    }

    // MARK: - Addition

    /// Returns the sum of two values.
    ///
    /// Returns `nil` on overflow or if the currencies do not match.
    ///
    /// ```swift
    /// let a = Money(105, currency: .gbp) // £1.05
    /// let b = Money(325, currency: .gbp) // £3.25
    /// let sum = a + b  // 430 (£4.30)
    /// ```
    public static func + (lhs: Self, rhs: Self) -> Self? {
        lhs.adding(rhs)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// Sets `lhs` to `nil` if it is already `nil`, the currencies do not match, or the result
    /// overflows.
    ///
    /// ```swift
    /// var total = Money(1_00, currency: .gbp) // £1.00
    /// total += Money(5, currency: .gbp)
    /// // total is now 105 (£1.05)
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to add.
    public static func += (lhs: inout Self?, rhs: Self) {
        lhs = lhs?.adding(rhs)
    }
}

extension Optional where Wrapped == Money {
    /// Returns the sum, or `nil` if `lhs` is `nil`, the currencies do not match, or the result
    /// overflows.
    public static func + (lhs: Self, rhs: Money) -> Money? {
        lhs.flatMap { $0.adding(rhs) }
    }

    /// Returns the sum, or `nil` if `rhs` is `nil`, the currencies do not match, or the result
    /// overflows.
    public static func + (lhs: Money, rhs: Self) -> Money? {
        rhs.flatMap { lhs.adding($0) }
    }
}

// MARK: - Subtraction

extension Money {
    func subtracting(_ rhs: Self) -> Self? {
        guard self.currency == rhs.currency else { return nil }

        let (result, didOverflow) = self.minorUnits.subtractingReportingOverflow(rhs.minorUnits)

        guard !didOverflow else { return nil }

        return Money(
            result,
            currency: self.currency,
        )
    }

    /// Returns the difference of two values.
    ///
    /// Returns `nil` on overflow or if the currencies do not match.
    ///
    /// ```swift
    /// let a = Money(10_50, currency: .gbp) // £10.50
    /// let b = Money(3_25, currency: .gbp) // £3.25
    /// let diff = a - b  // 725 (£7.25)
    /// ```
    public static func - (lhs: Self, rhs: Self) -> Self? {
        lhs.subtracting(rhs)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// Sets `lhs` to `nil` if it is already `nil`, the currencies do not match, or the result
    /// overflows.
    ///
    /// ```swift
    /// var balance = Money(100_00, currency: .gbp) // £100.00
    /// balance -= Money(25_50, currency: .gbp) // £25.50
    /// // balance is now 7450 // £74.50
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: The value to modify.
    ///   - rhs: The value to subtract.
    public static func -= (lhs: inout Self?, rhs: Self) {
        lhs = lhs?.subtracting(rhs)
    }
}

extension Optional where Wrapped == Money {
    /// Returns the difference, or `nil` if `lhs` is `nil`, the currencies do not match, or the
    /// result overflows.
    public static func - (lhs: Self, rhs: Money) -> Money? {
        lhs.flatMap { $0.subtracting(rhs) }
    }

    /// Returns the difference, or `nil` if `rhs` is `nil`, the currencies do not match, or the
    /// result overflows.
    public static func - (lhs: Money, rhs: Self) -> Money? {
        rhs.flatMap { lhs.subtracting($0) }
    }
}

// MARK: - Integral Multiplication

extension Money {
    func multiplied(by factor: Int) -> Self {
        Self(self.minorUnits * factor, currency: self.currency)
    }

    /// Returns the result of multiplying a `Money` value by an `Int` scalar.
    ///
    /// Traps on overflow.
    public static func * (lhs: Self, rhs: Int) -> Self {
        lhs.multiplied(by: rhs)
    }

    /// Returns the result of multiplying an `Int` scalar by a `Money` value.
    ///
    /// Traps on overflow.
    public static func * (lhs: Int, rhs: Self) -> Self {
        rhs.multiplied(by: lhs)
    }

    /// Multiplies a `Money` value by an `Int` scalar in place.
    ///
    /// Traps on overflow.
    public static func *= (lhs: inout Self, rhs: Int) {
        lhs = lhs * rhs
    }
}

extension Optional where Wrapped == Money {
    /// Returns the product, or `nil` if `lhs` is `nil`.
    ///
    /// Traps on overflow, unlike `+` and `-`, which return `nil`.
    public static func * (lhs: Self, rhs: Int) -> Money? {
        lhs.flatMap { $0.multiplied(by: rhs) }
    }

    /// Returns the product, or `nil` if `rhs` is `nil`.
    ///
    /// Traps on overflow, unlike `+` and `-`, which return `nil`.
    public static func * (lhs: Int, rhs: Self) -> Money? {
        rhs.flatMap { $0.multiplied(by: lhs) }
    }
}

// MARK: - Fractional Multiplication

#warning("TODO: scaled(by: Ratio) returning an exact/inexact result. Money never holds a fraction of a minor unit, so the caller resolves the remainder.")

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
