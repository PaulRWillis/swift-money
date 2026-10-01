public extension MoneyOf where C == AnyCurrency {
    /// Creates a runtime amount from a typed one, keeping its amount and currency.
    ///
    /// ```swift
    /// Money(GBP(minorUnits: 4_99))   // GBP 4.99, its currency now a value
    /// ```
    ///
    /// - Parameter typed: The amount whose currency is fixed by its type.
    @inlinable
    init<T: CurrencyType>(_ typed: MoneyOf<T>) {
        self.init(unchecked: typed.minorUnits, storage: T.currency)
    }
}

public extension MoneyOf where C: CurrencyType {
    /// Creates a typed amount from a runtime one, if it is in this type's currency.
    ///
    /// ```swift
    /// let price = try GBP(money)   // throws unless `money` is in pounds
    /// ```
    ///
    /// Currencies match only when code and scale both do, as they must for the amounts to combine.
    ///
    /// - Parameter money: The amount whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `money` is in another currency, with this
    ///   type's currency as `lhs`.
    @inlinable
    init(_ money: Money) throws(MoneyError) {
        try AnyCurrency.requireMatch(C.currency, money.storage)

        self.init(unchecked: money.minorUnits, storage: .implied)
    }
}
