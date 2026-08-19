public extension Money {
    /// An exact amount of the currency's smallest unit, which need not be a whole number of them.
    ///
    /// Scaling one leaves any fraction in place, so a chain settles once at the end rather than at
    /// every step.
    ///
    /// ```swift
    /// let balance = Money(minorUnits: 10_000_00, currency: .gbp)
    /// let interest = try balance.unrounded * Ratio(45, 1000) * Ratio(31, 365)
    /// interest.rounded(.toNearestOrEven)   // £38.22
    /// ```
    struct Unrounded: Equatable, Hashable, Sendable {
        private let currency: Currency
        private let minorUnits: Ratio

        fileprivate init(
            _ minorUnits: Ratio,
            currency: Currency
        ) {
            self.minorUnits = minorUnits
            self.currency = currency
        }
    }

    /// This amount, ready to be scaled without settling a fraction at each step.
    var unrounded: Unrounded {
        Unrounded(Ratio(Ratio.Numerator(minorUnits), 1), currency: currency)
    }
}

// MARK: - Scaling

public extension Money.Unrounded {
    /// Returns the result of scaling an unrounded amount by a fraction, keeping it exact.
    ///
    /// - Throws: ``MoneyError/overflow`` if the result is not representable.
    static func * (lhs: Self, rhs: Ratio) throws(MoneyError) -> Self {
        guard let scaled = lhs.minorUnits.multiplied(by: rhs) else {
            throw .overflow
        }

        return Self(scaled, currency: lhs.currency)
    }

    /// Returns the result of scaling an unrounded amount by a fraction, keeping it exact.
    ///
    /// - Throws: ``MoneyError/overflow`` if the result is not representable.
    static func * (lhs: Ratio, rhs: Self) throws(MoneyError) -> Self {
        try rhs * lhs
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// - Throws: ``MoneyError/overflow`` if the result is not representable.
    static func * (lhs: Self, rhs: Int) throws(MoneyError) -> Self {
        try lhs * Ratio(Ratio.Numerator(Int64(rhs)), 1)
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// - Throws: ``MoneyError/overflow`` if the result is not representable.
    static func * (lhs: Int, rhs: Self) throws(MoneyError) -> Self {
        try rhs * lhs
    }

    /// Scales an unrounded amount by a fraction in place, keeping it exact.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/overflow`` if the result is not representable.
    static func *= (lhs: inout Self, rhs: Ratio) throws(MoneyError) {
        lhs = try lhs * rhs
    }

    /// Scales an unrounded amount by a whole number in place.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/overflow`` if the result is not representable.
    static func *= (lhs: inout Self, rhs: Int) throws(MoneyError) {
        lhs = try lhs * rhs
    }
}

// MARK: - Addition and subtraction

private extension Money.Unrounded {
    func adding(_ other: Self) throws(MoneyError) -> Self {
        guard currency == other.currency else {
            throw .currencyMismatch(lhs: currency, rhs: other.currency)
        }

        guard let sum = minorUnits.adding(other.minorUnits) else {
            throw .overflow
        }

        return Self(sum, currency: currency)
    }

    func subtracting(_ other: Self) throws(MoneyError) -> Self {
        guard currency == other.currency else {
            throw .currencyMismatch(lhs: currency, rhs: other.currency)
        }

        guard let difference = minorUnits.subtracting(other.minorUnits) else {
            throw .overflow
        }

        return Self(difference, currency: currency)
    }
}

public extension Money.Unrounded {
    /// Returns the sum of two unrounded amounts, keeping both exact.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the sum is not representable.
    static func + (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try lhs.adding(rhs)
    }

    /// Returns the difference of two unrounded amounts, keeping both exact.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the difference is not representable.
    static func - (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try lhs.subtracting(rhs)
    }

    /// Adds an unrounded amount in place.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the sum is not representable.
    static func += (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs.adding(rhs)
    }

    /// Subtracts an unrounded amount in place.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the difference is not representable.
    static func -= (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs.subtracting(rhs)
    }
}

// MARK: - Mixing with settled money

// A settled amount widens to an unrounded one exactly, so these lose nothing. The expression is already
// marked by an `.unrounded` somewhere in it, which is what keeps the opt-in visible.
public extension Money.Unrounded {
    /// Returns the sum of an unrounded amount and a settled one.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the sum is not representable.
    static func + (lhs: Self, rhs: Money) throws(MoneyError) -> Self {
        try lhs.adding(rhs.unrounded)
    }

    /// Returns the sum of a settled amount and an unrounded one.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the sum is not representable.
    static func + (lhs: Money, rhs: Self) throws(MoneyError) -> Self {
        try lhs.unrounded.adding(rhs)
    }

    /// Returns a settled amount subtracted from an unrounded one.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the difference is not representable.
    static func - (lhs: Self, rhs: Money) throws(MoneyError) -> Self {
        try lhs.subtracting(rhs.unrounded)
    }

    /// Returns an unrounded amount subtracted from a settled one.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the difference is not representable.
    static func - (lhs: Money, rhs: Self) throws(MoneyError) -> Self {
        try lhs.unrounded.subtracting(rhs)
    }

    /// Adds a settled amount to an unrounded one in place.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the sum is not representable.
    static func += (lhs: inout Self, rhs: Money) throws(MoneyError) {
        lhs = try lhs.adding(rhs.unrounded)
    }

    /// Subtracts a settled amount from an unrounded one in place.
    ///
    /// `lhs` is left untouched when this throws.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ, or
    ///   ``MoneyError/overflow`` if the difference is not representable.
    static func -= (lhs: inout Self, rhs: Money) throws(MoneyError) {
        lhs = try lhs.subtracting(rhs.unrounded)
    }
}

// MARK: - Settling

public extension Money.Unrounded {
    /// Returns this amount as a whole number of the currency's smallest unit.
    ///
    /// ```swift
    /// let third = try Money(minorUnits: 10_00, currency: .gbp).unrounded * Ratio(1, 3)
    /// third.rounded(.toNearestOrEven)   // £3.33
    /// ```
    ///
    /// - Parameter rule: How to settle any fraction of a unit.
    func rounded(_ rule: RoundingRule) -> Money {
        Money(minorUnits: SwiftMoney.rounded(minorUnits, rule), currency: currency)
    }
}

