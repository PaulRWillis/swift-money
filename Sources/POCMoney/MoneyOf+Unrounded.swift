public extension MoneyOf {
    /// An exact amount of the currency's smallest unit, which need not be a whole number of them.
    ///
    /// Scaling one leaves any fraction in place, so a chain settles once at the end rather than at
    /// every step.
    ///
    /// ```swift
    /// let interest = GBP(10_000_00).unrounded * Ratio(45, 1000) * Ratio(31, 365)
    /// interest.rounded(.toNearestOrEven)   // £38.22
    /// ```
    struct Unrounded: Equatable, Hashable, Sendable {
        private let minorUnits: Ratio

        fileprivate init(_ minorUnits: Ratio) {
            self.minorUnits = minorUnits
        }
    }

    /// This amount, ready to be scaled without settling a fraction at each step.
    var unrounded: Unrounded {
        Unrounded(Ratio(Ratio.Numerator(minorUnits), 1))
    }
}

// MARK: - Scaling

public extension MoneyOf.Unrounded {
    /// Returns the result of scaling an unrounded amount by a fraction, keeping it exact.
    ///
    /// Traps on overflow.
    static func * (lhs: Self, rhs: Ratio) -> Self {
        guard let scaled = lhs.minorUnits.multiplied(by: rhs) else {
            preconditionFailure("Scaling by \(rhs) is not representable")
        }

        return Self(scaled)
    }

    /// Returns the result of scaling an unrounded amount by a fraction, keeping it exact.
    ///
    /// Traps on overflow.
    static func * (lhs: Ratio, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    static func * (lhs: Self, rhs: Int) -> Self {
        lhs * Ratio(Ratio.Numerator(Int64(rhs)), 1)
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    static func * (lhs: Int, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Scales an unrounded amount by a fraction in place, keeping it exact.
    ///
    /// Traps on overflow.
    static func *= (lhs: inout Self, rhs: Ratio) {
        lhs = lhs * rhs
    }

    /// Scales an unrounded amount by a whole number in place.
    ///
    /// Traps on overflow.
    static func *= (lhs: inout Self, rhs: Int) {
        lhs = lhs * rhs
    }
}

// MARK: - Settling

public extension MoneyOf.Unrounded {
    /// Returns this amount as a whole number of the currency's smallest unit.
    ///
    /// ```swift
    /// (GBP(10_00).unrounded * Ratio(1, 3)).rounded(.toNearestOrEven)   // £3.33
    /// ```
    ///
    /// - Parameter mode: How to settle any fraction of a unit.
    func rounded(_ mode: RoundingMode) -> MoneyOf<C> {
        MoneyOf(POCMoney.rounded(minorUnits, mode))
    }
}

#warning("TODO: Signpost `Money * Ratio` at `.unrounded` and `scaled(by:rounding:)`")
