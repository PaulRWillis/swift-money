public extension MoneyOf {
    /// An amount of the currency's smallest unit that need not be a whole number of them.
    ///
    /// Scaling one keeps the fraction of a unit rather than settling it, so a chain of scalings settles
    /// once at the end instead of at every step, and the result lands within one minor unit of the exact
    /// figure. Settling at every step is what loses money: a year of daily interest on GBP 10,000 at 4.5%
    /// comes to about GBP 450.00 settled once, and GBP 448.95 settled daily.
    ///
    /// ```swift
    /// let interest = GBP(minorUnits: 10_000_00).unrounded * "0.045" * Rate(string: "31/365")!
    /// interest.rounded(.toNearestOrEven)   // about £38.22
    /// ```
    struct Unrounded: Equatable, Hashable, Sendable {
        // The count of minor units, which may hold a fraction of one until it is settled.
        fileprivate let minorUnits: Fixed
        fileprivate let storage: C.Storage

        fileprivate init(
            _ minorUnits: Fixed,
            storage: C.Storage
        ) {
            self.minorUnits = minorUnits
            self.storage = storage
        }
    }

    /// This amount, ready to be scaled without settling a fraction at each step.
    var unrounded: Unrounded {
        Unrounded(Fixed(minorUnits), storage: storage)
    }
}

public extension MoneyOf.Unrounded where C: CurrencyType {
    /// Returns the result of scaling an unrounded amount by a rate, keeping the fraction for one settling.
    ///
    /// Traps on overflow.
    static func * (lhs: Self, rhs: Rate) -> Self {
        guard let scaled = lhs.minorUnits.multipliedIfRepresentable(by: rhs.value) else {
            preconditionFailure("Scaling by a rate is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(scaled, storage: .implied)
    }

    /// Returns the result of scaling an unrounded amount by a rate, keeping the fraction for one settling.
    ///
    /// Traps on overflow.
    static func * (lhs: Rate, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        guard let scaled = lhs.minorUnits.multipliedIfRepresentable(by: rhs) else {
            preconditionFailure("Scaling by \(rhs) is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(scaled, storage: .implied)
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    static func * (lhs: some BinaryInteger, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Scales an unrounded amount by a rate in place.
    ///
    /// Traps on overflow.
    static func *= (lhs: inout Self, rhs: Rate) {
        lhs = lhs * rhs
    }

    /// Scales an unrounded amount by a whole number in place.
    ///
    /// Traps on overflow.
    static func *= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs * rhs
    }

    /// Returns this amount scaled by a rate. The named form of `*`.
    ///
    /// Traps on overflow.
    func applying(_ rate: Rate) -> Self {
        self * rate
    }

    /// Returns this amount divided by a whole number, keeping the fraction for one settling.
    ///
    /// Multiplying before dividing (`balance * rate` then `.divided(by: 365)`) keeps more of the value
    /// than scaling by a tiny rate would.
    ///
    /// - Precondition: `n` is not zero.
    func divided(by n: some BinaryInteger) -> Self {
        Self(minorUnits.divided(by: n), storage: .implied)
    }

    /// Returns this amount divided by a whole number, or `nil` if `n` is zero.
    func divided(byExactly n: some BinaryInteger) -> Self? {
        guard n != 0 else {
            return nil
        }

        return Self(minorUnits.divided(by: n), storage: .implied)
    }

    /// Returns this amount settled to a whole number of the currency's smallest unit, within one of the
    /// exact figure.
    ///
    /// ```swift
    /// (GBP(minorUnits: 10_00).unrounded * Rate(string: "1/3")!).rounded(.toNearestOrEven)   // £3.33
    /// ```
    ///
    /// - Parameter rule: How to settle any fraction of a unit.
    /// - Precondition: the settled amount is representable.
    func rounded(_ rule: RoundingRule) -> MoneyOf<C> {
        guard let settled = Int64(exactly: Int128(minorUnits, rounding: rule)) else {
            preconditionFailure("Settled amount is out of range")  // coverage:ignore — exit-test trap
        }

        return MoneyOf(unchecked: settled, storage: .implied)
    }
}

extension MoneyOf.Unrounded: AdditiveArithmetic where C: CurrencyType {
    public static var zero: Self {
        MoneyOf<C>.zero.unrounded
    }

    /// Returns the sum of two unrounded amounts, keeping both fractions.
    ///
    /// Traps on overflow.
    public static func + (lhs: Self, rhs: Self) -> Self {
        guard let sum = lhs.minorUnits.addingIfRepresentable(rhs.minorUnits) else {
            preconditionFailure("Adding is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(sum, storage: .implied)
    }

    /// Returns the difference of two unrounded amounts, keeping both fractions.
    ///
    /// Traps on overflow.
    public static func - (lhs: Self, rhs: Self) -> Self {
        guard let difference = lhs.minorUnits.subtractingIfRepresentable(rhs.minorUnits) else {
            preconditionFailure("Subtracting is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(difference, storage: .implied)
    }
}

// A settled amount widens to an unrounded one exactly, so these lose nothing. The expression is
// already marked by an `.unrounded` somewhere in it, which is what keeps the opt-in visible.
public extension MoneyOf.Unrounded where C: CurrencyType {
    /// Returns the sum of an unrounded amount and a settled one.
    static func + (lhs: Self, rhs: MoneyOf<C>) -> Self {
        lhs + rhs.unrounded
    }

    /// Returns the sum of a settled amount and an unrounded one.
    static func + (lhs: MoneyOf<C>, rhs: Self) -> Self {
        lhs.unrounded + rhs
    }

    /// Returns a settled amount subtracted from an unrounded one.
    static func - (lhs: Self, rhs: MoneyOf<C>) -> Self {
        lhs - rhs.unrounded
    }

    /// Returns an unrounded amount subtracted from a settled one.
    static func - (lhs: MoneyOf<C>, rhs: Self) -> Self {
        lhs.unrounded - rhs
    }

    /// Adds a settled amount to an unrounded one in place.
    static func += (lhs: inout Self, rhs: MoneyOf<C>) {
        lhs = lhs + rhs
    }

    /// Subtracts a settled amount from an unrounded one in place.
    static func -= (lhs: inout Self, rhs: MoneyOf<C>) {
        lhs = lhs - rhs
    }
}

public extension MoneyOf.Unrounded where C == AnyCurrency {
    /// Returns the result of scaling an unrounded amount by a rate, keeping the fraction for one settling.
    ///
    /// Traps on overflow.
    static func * (lhs: Self, rhs: Rate) -> Self {
        guard let scaled = lhs.minorUnits.multipliedIfRepresentable(by: rhs.value) else {
            preconditionFailure("Scaling by a rate is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(scaled, storage: lhs.storage)
    }

    /// Returns the result of scaling an unrounded amount by a rate, keeping the fraction for one settling.
    ///
    /// Traps on overflow.
    static func * (lhs: Rate, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    static func * (lhs: Self, rhs: some BinaryInteger) -> Self {
        guard let scaled = lhs.minorUnits.multipliedIfRepresentable(by: rhs) else {
            preconditionFailure("Scaling by \(rhs) is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(scaled, storage: lhs.storage)
    }

    /// Returns the result of scaling an unrounded amount by a whole number.
    ///
    /// Traps on overflow.
    static func * (lhs: some BinaryInteger, rhs: Self) -> Self {
        rhs * lhs
    }

    /// Scales an unrounded amount by a rate in place.
    ///
    /// Traps on overflow.
    static func *= (lhs: inout Self, rhs: Rate) {
        lhs = lhs * rhs
    }

    /// Scales an unrounded amount by a whole number in place.
    ///
    /// Traps on overflow.
    static func *= (lhs: inout Self, rhs: some BinaryInteger) {
        lhs = lhs * rhs
    }

    /// Returns this amount scaled by a rate. The named form of `*`.
    ///
    /// Traps on overflow.
    func applying(_ rate: Rate) -> Self {
        self * rate
    }

    /// Returns this amount divided by a whole number, keeping the fraction for one settling.
    ///
    /// - Precondition: `n` is not zero.
    func divided(by n: some BinaryInteger) -> Self {
        Self(minorUnits.divided(by: n), storage: storage)
    }

    /// Returns this amount divided by a whole number, or `nil` if `n` is zero.
    func divided(byExactly n: some BinaryInteger) -> Self? {
        guard n != 0 else {
            return nil
        }

        return Self(minorUnits.divided(by: n), storage: storage)
    }

    /// Returns the sum of two unrounded amounts, keeping both fractions.
    ///
    /// Traps on overflow.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    static func + (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try AnyCurrency.requireMatch(lhs.storage, rhs.storage)

        guard let sum = lhs.minorUnits.addingIfRepresentable(rhs.minorUnits) else {
            preconditionFailure("Adding is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(sum, storage: lhs.storage)
    }

    /// Returns the difference of two unrounded amounts, keeping both fractions.
    ///
    /// Traps on overflow.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the currencies differ.
    static func - (lhs: Self, rhs: Self) throws(MoneyError) -> Self {
        try AnyCurrency.requireMatch(lhs.storage, rhs.storage)

        guard let difference = lhs.minorUnits.subtractingIfRepresentable(rhs.minorUnits) else {
            preconditionFailure("Subtracting is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(difference, storage: lhs.storage)
    }

    /// Adds one unrounded amount to another in place.
    static func += (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs + rhs
    }

    /// Subtracts one unrounded amount from another in place.
    static func -= (lhs: inout Self, rhs: Self) throws(MoneyError) {
        lhs = try lhs - rhs
    }

    /// Returns the sum of an unrounded amount and a settled one.
    static func + (lhs: Self, rhs: Money) throws(MoneyError) -> Self {
        try lhs + rhs.unrounded
    }

    /// Returns the sum of a settled amount and an unrounded one.
    static func + (lhs: Money, rhs: Self) throws(MoneyError) -> Self {
        try lhs.unrounded + rhs
    }

    /// Returns a settled amount subtracted from an unrounded one.
    static func - (lhs: Self, rhs: Money) throws(MoneyError) -> Self {
        try lhs - rhs.unrounded
    }

    /// Returns an unrounded amount subtracted from a settled one.
    static func - (lhs: Money, rhs: Self) throws(MoneyError) -> Self {
        try lhs.unrounded - rhs
    }

    /// Adds a settled amount to an unrounded one in place.
    static func += (lhs: inout Self, rhs: Money) throws(MoneyError) {
        lhs = try lhs + rhs
    }

    /// Subtracts a settled amount from an unrounded one in place.
    static func -= (lhs: inout Self, rhs: Money) throws(MoneyError) {
        lhs = try lhs - rhs
    }

    /// Returns this amount settled to a whole number of the currency's smallest unit, within one of the
    /// exact figure.
    ///
    /// - Parameter rule: How to settle any fraction of a unit.
    /// - Precondition: the settled amount is representable.
    func rounded(_ rule: RoundingRule) -> Money {
        guard let settled = Int64(exactly: Int128(minorUnits, rounding: rule)) else {
            preconditionFailure("Settled amount is out of range")  // coverage:ignore — exit-test trap
        }

        return Money(unchecked: settled, storage: storage)
    }
}

public extension MoneyOf.Unrounded where C: CurrencyType {
    /// Creates an amount from a fractional number of the currency's major units.
    ///
    /// `GBP.Unrounded(majorUnits: "0.023")` is 2.3 pence, ready to scale and settle once.
    ///
    /// - Precondition: the amount is representable.
    init(majorUnits: Rate) {
        self.init(majorUnits.value.multiplied(by: Int64(C.currency.unitScale)), storage: .implied)
    }

    /// Creates an amount from a fractional number of the currency's minor units.
    ///
    /// `GBP.Unrounded(minorUnits: "2.3")` is 2.3 pence.
    init(minorUnits: Rate) {
        self.init(minorUnits.value, storage: .implied)
    }
}
