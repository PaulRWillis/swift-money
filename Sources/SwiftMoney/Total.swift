public extension Sequence {
    /// Returns the sum of every amount, or zero if there are none.
    ///
    /// ```swift
    /// [GBP(minorUnits: 1_00), GBP(minorUnits: 2_50)].total()   // £3.50
    /// ```
    ///
    /// - Precondition: The sum is representable. Totalling beyond ``MoneyOf/max`` traps, as `+` does.
    @inlinable
    func total<C: CurrencyType>() -> MoneyOf<C> where Element == MoneyOf<C> {
        reduce(.zero, +)
    }

    /// Returns the sum of every amount, or zero if there are none, keeping every fraction exact.
    ///
    /// ```swift
    /// let daily = balance.unrounded * "45/365000"
    /// Array(repeating: daily, count: 365).total()   // a year, with nothing lost to rounding
    /// ```
    ///
    /// - Precondition: The sum is representable. Totalling beyond ``MoneyOf/max`` traps, as `+` does.
    @inlinable
    func total<C: CurrencyType>() -> MoneyOf<C>.Unrounded where Element == MoneyOf<C>.Unrounded {
        reduce(.zero, +)
    }
}

public extension Sequence where Element == Money {
    /// Returns the sum of every amount, or `nil` if there are none.
    ///
    /// An empty sequence has no total because a zero cannot exist without a currency to be zero *of*.
    ///
    /// ```swift
    /// let basket = [Money(minorUnits: 1_00, currency: .gbp), Money(minorUnits: 2_50, currency: .gbp)]
    /// try basket.total()   // £3.50
    /// ```
    ///
    /// Traps on overflow.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the amounts are not all in the same
    ///   currency.
    @inlinable
    func total() throws(MoneyError) -> Money? {
        var running: Money?

        // Written as a loop rather than with `reduce` or `map`: both are `rethrows`, which erases the
        // typed error to `any Error` and so cannot satisfy `throws(MoneyError)`.
        for amount in self {
            guard let current = running else {
                running = amount
                continue
            }

            running = try current + amount
        }

        return running
    }
}

public extension Sequence where Element == Money.Unrounded {
    /// Returns the sum of every amount, or `nil` if there are none, keeping every fraction exact.
    ///
    /// An empty sequence has no total because a zero cannot exist without a currency to be zero *of*.
    ///
    /// Traps on overflow.
    ///
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if the amounts are not all in the same
    ///   currency.
    @inlinable
    func total() throws(MoneyError) -> Money.Unrounded? {
        var running: Money.Unrounded?

        for amount in self {
            guard let current = running else {
                running = amount
                continue
            }

            running = try current + amount
        }

        return running
    }
}
