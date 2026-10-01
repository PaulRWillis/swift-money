/// Every runtime amount at or above a lower bound, in the bound's currency.
///
/// The runtime counterpart of `PartialRangeFrom<GBP>`, written with the postfix `...` operator:
///
/// ```swift
/// let atLeastMinimum = minimum...
/// try atLeastMinimum.contains(amount)   // throws only if `amount` is in another currency
/// ```
///
/// Not a `Sequence`, unlike the standard library's: an amount has no single next amount to step to
/// until a stride says how far.
public struct PartialMoneyRangeFrom: Equatable, Hashable, Sendable {
    /// The range's lower bound, which the range contains.
    public let lowerBound: Money

    /// Creates a range of every amount at or above a lower bound.
    ///
    /// - Parameter lowerBound: The lower bound, which the range contains.
    @inlinable
    public init(_ lowerBound: Money) {
        self.lowerBound = lowerBound
    }

    /// Creates a runtime range from a typed one, keeping its bound and currency.
    ///
    /// ```swift
    /// let atLeastMinimum = PartialMoneyRangeFrom(GBP(minorUnits: 10_00)...)
    /// atLeastMinimum.lowerBound   // GBP 10.00
    /// ```
    ///
    /// - Parameter typed: The range whose currency is fixed by its bound's type.
    @inlinable
    public init<C: CurrencyType>(_ typed: PartialRangeFrom<MoneyOf<C>>) {
        self.init(Money(typed.lowerBound))
    }

    /// The currency the lower bound, and every amount in the range, are denominated in.
    @inlinable
    public var currency: Currency {
        lowerBound.currency
    }

    /// Returns whether an amount lies at or above the lower bound.
    ///
    /// - Parameter amount: The amount to look for.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the bound's currency as `lhs`.
    @inlinable
    public func contains(_ amount: Money) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(lowerBound.storage, amount.storage)

        return amount.minorUnits >= lowerBound.minorUnits
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns the range of every amount at or above a lower bound.
    ///
    /// One bound has no order to check, so unlike `...` between two amounts this cannot fail.
    ///
    /// - Parameter minimum: The lower bound, which the range contains.
    @inlinable
    static postfix func ... (minimum: Money) -> PartialMoneyRangeFrom {
        PartialMoneyRangeFrom(minimum)
    }
}
