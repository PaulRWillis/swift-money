public extension Money {
    /// An exact amount of the currency's smallest unit, which need not be a whole number of them.
    ///
    /// Scaling one leaves any fraction in place, so a chain settles once at the end rather than at
    /// every step.
    ///
    /// ```swift
    /// let balance = Money(10_000_00, currency: .gbp)
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

// MARK: - Settling

public extension Money.Unrounded {
    /// Returns this amount as a whole number of the currency's smallest unit.
    ///
    /// ```swift
    /// let third = try Money(10_00, currency: .gbp).unrounded * Ratio(1, 3)
    /// third.rounded(.toNearestOrEven)   // £3.33
    /// ```
    ///
    /// - Parameter mode: How to settle any fraction of a unit.
    func rounded(_ mode: RoundingMode) -> Money {
        Money(POCMoney.rounded(minorUnits, mode), currency: currency)
    }
}

