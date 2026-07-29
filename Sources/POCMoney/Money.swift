public struct Money: Equatable, Hashable, Sendable {

    // MARK: - Private Properties

    private let minorUnits: Int
    private let currency: String

    // MARK: - Initializers

    public init(
        _ minorUnits: Int,
        currency: String,
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
    /// Returns nil on overflow or if the currencies do not match.
    ///
    /// ```swift
    /// let a = Money(105, currency: "GBP") // £1.05
    /// let b = Money(325, currency: "GBP") // £3.25
    /// let sum = a + b  // 430 (£4.30)
    /// ```
    public static func + (lhs: Self, rhs: Self) -> Self? {
        lhs.adding(rhs)
    }

    /// Adds the right-hand value to the left-hand value in place.
    ///
    /// Returns nil on overflow or if the currencies do not match.
    ///
    /// ```swift
    /// var total = Money(1_00, currency: "GBP") // £1.00
    /// total += Money(5, currency: "GBP")
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
    public static func + (lhs: Self, rhs: Money) -> Money? {
        lhs.flatMap { $0.adding(rhs) }
    }

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
    /// Returns nil on overflow or if the currencies do not match.
    ///
    /// ```swift
    /// let a = Money(10_50, currency: "GBP") // £10.50
    /// let b = Money(3_25, currency: "GBP") // £3.25
    /// let diff = a - b  // 725 (£7.25)
    /// ```
    public static func - (lhs: Self, rhs: Self) -> Self? {
        lhs.subtracting(rhs)
    }

    /// Subtracts the right-hand value from the left-hand value in place.
    ///
    /// Returns nil on overflow or if the currencies do not match.
    ///
    /// ```swift
    /// var balance = Money(100_00, currency: "GBP") // £100.00
    /// balance -= GBP(25_50 currency: "GBP") // £25.50
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
    public static func - (lhs: Self, rhs: Money) -> Money? {
        lhs.flatMap { $0.subtracting(rhs) }
    }

    public static func - (lhs: Money, rhs: Self) -> Money? {
        rhs.flatMap { lhs.subtracting($0) }
    }
}

// MARK: - Integral Multiplication

extension Money {
    func multiplied(by factor: Int) -> Self {
        Self(self.minorUnits * factor, currency: self.currency)
    }

    /// Returns the result of multiplying a `MoneyOf` value by an `Int` scalar.
    ///
    /// Traps on overflow.
    public static func * (lhs: Self, rhs: Int) -> Self {
        lhs.multiplied(by: rhs)
    }

    /// Returns the result of multiplying an `Int` scalar by a `MoneyOf` value.
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
    public static func * (lhs: Self, rhs: Int) -> Money? {
        lhs.flatMap { $0.multiplied(by: rhs) }
    }

    public static func * (lhs: Int, rhs: Self) -> Money? {
        rhs.flatMap { $0.multiplied(by: lhs) }
    }
}

// MARK: - Fractional Multiplication

#warning("TODO")

// MARK: - Split

extension Money {
    public func distributed(
        into count: PartCount
    ) -> Split<Self> {
        POCMoney.distributed(minorUnits, into: count)
            .map { Money($0, currency: currency) }
    }
}

#warning("TODO: Subunit pricing")
#warning("TODO: Currency conversion")
#warning("TODO: Minor units as MinorUnit")
#warning("TODO: Currency property as CurrencyCode")
