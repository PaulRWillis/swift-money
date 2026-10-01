/// Every runtime amount below an upper bound, in the bound's currency.
///
/// The runtime counterpart of `PartialRangeUpTo<GBP>`, written with the prefix `..<` operator:
///
/// ```swift
/// let underLimit = ..<limit
/// try underLimit.contains(amount)   // throws only if `amount` is in another currency
/// ```
public struct PartialMoneyRangeUpTo: Equatable, Hashable, Sendable {
    /// The range's upper bound, which the range does not contain.
    public let upperBound: Money

    /// Creates a range of every amount below an upper bound.
    ///
    /// - Parameter upperBound: The upper bound, which the range does not contain.
    @inlinable
    public init(_ upperBound: Money) {
        self.upperBound = upperBound
    }

    /// Creates a runtime range from a typed one, keeping its bound and currency.
    ///
    /// ```swift
    /// let underLimit = PartialMoneyRangeUpTo(..<GBP(minorUnits: 250_00))
    /// underLimit.upperBound   // GBP 250.00
    /// ```
    ///
    /// - Parameter typed: The range whose currency is fixed by its bound's type.
    @inlinable
    public init<C: CurrencyType>(_ typed: PartialRangeUpTo<MoneyOf<C>>) {
        self.init(Money(typed.upperBound))
    }

    /// Returns whether an amount lies below the upper bound.
    ///
    /// - Parameter amount: The amount to look for.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the bound's currency as `lhs`.
    @inlinable
    public func contains(_ amount: Money) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(upperBound.storage, amount.storage)

        return amount.minorUnits < upperBound.minorUnits
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns the range of every amount below an upper bound.
    ///
    /// One bound has no order to check, so unlike `..<` between two amounts this cannot fail.
    ///
    /// - Parameter maximum: The upper bound, which the range does not contain.
    @inlinable
    static prefix func ..< (maximum: Money) -> PartialMoneyRangeUpTo {
        PartialMoneyRangeUpTo(maximum)
    }
}
