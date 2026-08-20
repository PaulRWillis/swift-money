public extension MoneyOf {
    /// An exact amount of the currency's smallest unit, which need not be a whole number of them.
    ///
    /// Scaling one leaves any fraction in place, so a chain settles once at the end rather than at
    /// every step. Rounding at every step is what loses money: a year of daily interest on GBP 10,000
    /// at 4.5% comes to GBP 450.00 settled once, and GBP 448.95 settled daily.
    ///
    /// ```swift
    /// let interest = GBP(minorUnits: 10_000_00).unrounded * Ratio(45, 1000) * Ratio(31, 365)
    /// interest.rounded(.toNearestOrEven)   // £38.22
    /// ```
    struct Unrounded: Equatable, Hashable, Sendable {
        @usableFromInline
        let minorUnits: Ratio

        @usableFromInline
        let storage: C.Storage

        @inlinable
        init(
            _ minorUnits: Ratio,
            storage: C.Storage
        ) {
            self.minorUnits = minorUnits
            self.storage = storage
        }
    }

    /// This amount, ready to be scaled without settling a fraction at each step.
    @inlinable
    var unrounded: Unrounded {
        Unrounded(Ratio(Ratio.Numerator(minorUnits), 1), storage: storage)
    }
}

// MARK: - A currency fixed at compile time: scaling cannot fail

public extension MoneyOf.Unrounded where C: CurrencyType {
    /// Returns the result of scaling an unrounded amount by a fraction, keeping it exact.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: Self, rhs: Ratio) -> Self {
        guard let scaled = lhs.minorUnits.multiplied(by: rhs) else {
            preconditionFailure("Scaling by \(rhs) is not representable")
        }

        return Self(scaled, storage: .implied)
    }

    /// Returns the result of scaling an unrounded amount by a fraction, keeping it exact.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: Ratio, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        lhs * Ratio(Ratio.Numerator(Int64(rhs)), 1)
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: some BinaryInteger, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Scales an unrounded amount by a fraction in place, keeping it exact.
    ///
    /// Traps on overflow.
    @inlinable
    static func *= (lhs: inout Self, rhs: Ratio) {
        lhs = lhs * rhs
    }

    /// Scales an unrounded amount by a whole number in place.
    ///
    /// Traps on overflow.
    @inlinable
    static func *= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs * rhs
    }

    /// Returns this amount as a whole number of the currency's smallest unit.
    ///
    /// ```swift
    /// (GBP(minorUnits: 10_00).unrounded * Ratio(1, 3)).rounded(.toNearestOrEven)   // £3.33
    /// ```
    ///
    /// - Parameter rule: How to settle any fraction of a unit.
    @inlinable
    func rounded(_ rule: RoundingRule) -> MoneyOf<C> {
        MoneyOf(unchecked: SwiftMoney.rounded(minorUnits, rule), storage: .implied)
    }
}

extension MoneyOf.Unrounded: AdditiveArithmetic where C: CurrencyType {
    @inlinable
    public static var zero: Self {
        MoneyOf<C>.zero.unrounded
    }

    /// Returns the sum of two unrounded amounts, keeping both exact.
    ///
    /// Traps on overflow.
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        guard let sum = lhs.minorUnits.adding(rhs.minorUnits) else {
            preconditionFailure("Adding \(rhs) is not representable")
        }

        return Self(sum, storage: .implied)
    }

    /// Returns the difference of two unrounded amounts, keeping both exact.
    ///
    /// Traps on overflow.
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        guard let difference = lhs.minorUnits.subtracting(rhs.minorUnits) else {
            preconditionFailure("Subtracting \(rhs) is not representable")
        }

        return Self(difference, storage: .implied)
    }
}

// A settled amount widens to an unrounded one exactly, so these lose nothing. The expression is
// already marked by an `.unrounded` somewhere in it, which is what keeps the opt-in visible.
public extension MoneyOf.Unrounded where C: CurrencyType {
    /// Returns the sum of an unrounded amount and a settled one.
    @inlinable
    static func + (lhs: Self, rhs: MoneyOf<C>) -> Self {
        lhs + rhs.unrounded
    }

    /// Returns the sum of a settled amount and an unrounded one.
    @inlinable
    static func + (lhs: MoneyOf<C>, rhs: Self) -> Self {
        lhs.unrounded + rhs
    }

    /// Returns a settled amount subtracted from an unrounded one.
    @inlinable
    static func - (lhs: Self, rhs: MoneyOf<C>) -> Self {
        lhs - rhs.unrounded
    }

    /// Returns an unrounded amount subtracted from a settled one.
    @inlinable
    static func - (lhs: MoneyOf<C>, rhs: Self) -> Self {
        lhs.unrounded - rhs
    }

    /// Adds a settled amount to an unrounded one in place.
    @inlinable
    static func += (lhs: inout Self, rhs: MoneyOf<C>) {
        lhs = lhs + rhs
    }

    /// Subtracts a settled amount from an unrounded one in place.
    @inlinable
    static func -= (lhs: inout Self, rhs: MoneyOf<C>) {
        lhs = lhs - rhs
    }
}

// MARK: - A currency only known at runtime: arithmetic can fail

public extension MoneyOf.Unrounded where C == AnyCurrency {
    /// Returns the result of scaling an unrounded amount by a fraction, keeping it exact.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: Self, rhs: Ratio) -> Self {
        guard let scaled = lhs.minorUnits.multiplied(by: rhs) else {
            preconditionFailure("Scaling by \(rhs) is not representable")
        }

        return Self(scaled, storage: lhs.storage)
    }

    /// Returns the result of scaling an unrounded amount by a fraction, keeping it exact.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: Ratio, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        lhs * Ratio(Ratio.Numerator(Int64(rhs)), 1)
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    @inlinable
    static func * (lhs: some BinaryInteger, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Scales an unrounded amount by a fraction in place, keeping it exact.
    ///
    /// Traps on overflow.
    @inlinable
    static func *= (lhs: inout Self, rhs: Ratio) {
        lhs = lhs * rhs
    }

    /// Scales an unrounded amount by a whole number in place.
    ///
    /// Traps on overflow.
    @inlinable
    static func *= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs * rhs
    }

    /// Returns the sum of two unrounded amounts, keeping both exact.
    ///
    /// Traps on overflow.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    @inlinable
    static func + (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try AnyCurrency.requireMatch(lhs.storage, rhs.storage)

        guard let sum = lhs.minorUnits.adding(rhs.minorUnits) else {
            preconditionFailure("Adding \(rhs) is not representable")
        }

        return Self(sum, storage: lhs.storage)
    }

    /// Returns the difference of two unrounded amounts, keeping both exact.
    ///
    /// Traps on overflow.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    @inlinable
    static func - (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try AnyCurrency.requireMatch(lhs.storage, rhs.storage)

        guard let difference = lhs.minorUnits.subtracting(rhs.minorUnits) else {
            preconditionFailure("Subtracting \(rhs) is not representable")
        }

        return Self(difference, storage: lhs.storage)
    }

    /// Adds one unrounded amount to another in place.
    @inlinable
    static func += (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs + rhs
    }

    /// Subtracts one unrounded amount from another in place.
    @inlinable
    static func -= (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs - rhs
    }

    /// Returns the sum of an unrounded amount and a settled one.
    @inlinable
    static func + (lhs: Self, rhs: Money) throws(MoneyError) -> Self {
        try lhs + rhs.unrounded
    }

    /// Returns the sum of a settled amount and an unrounded one.
    @inlinable
    static func + (lhs: Money, rhs: Self) throws(MoneyError) -> Self {
        try lhs.unrounded + rhs
    }

    /// Returns a settled amount subtracted from an unrounded one.
    @inlinable
    static func - (lhs: Self, rhs: Money) throws(MoneyError) -> Self {
        try lhs - rhs.unrounded
    }

    /// Returns an unrounded amount subtracted from a settled one.
    @inlinable
    static func - (lhs: Money, rhs: Self) throws(MoneyError) -> Self {
        try lhs.unrounded - rhs
    }

    /// Adds a settled amount to an unrounded one in place.
    @inlinable
    static func += (lhs: inout Self, rhs: Money) throws(MoneyError) {
        lhs = try lhs + rhs
    }

    /// Subtracts a settled amount from an unrounded one in place.
    @inlinable
    static func -= (lhs: inout Self, rhs: Money) throws(MoneyError) {
        lhs = try lhs - rhs
    }

    /// Returns this amount as a whole number of the currency's smallest unit.
    ///
    /// - Parameter rule: How to settle any fraction of a unit.
    @inlinable
    func rounded(_ rule: RoundingRule) -> Money {
        Money(unchecked: SwiftMoney.rounded(minorUnits, rule), storage: storage)
    }
}
