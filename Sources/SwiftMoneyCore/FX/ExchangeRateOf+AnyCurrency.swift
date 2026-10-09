public extension FX.ExchangeRateOf where From == AnyCurrency, To == AnyCurrency {
    /// Creates a runtime rate from a typed one, keeping its quote and its pair.
    ///
    /// ```swift
    /// let eurGbp = FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.87")!
    /// FX.ExchangeRate(eurGbp).from   // EUR, its currency now a value
    /// ```
    ///
    /// - Parameter rate: The rate whose currencies are fixed by its type.
    @inlinable
    init<F: CurrencyType, T: CurrencyType>(_ rate: FX.ExchangeRateOf<F, T>) {
        self.init(unchecked: rate.minorPerMinorRate, fromStorage: F.currency, toStorage: T.currency)
    }
}

public extension FX.ExchangeRateOf where From: CurrencyType, To: CurrencyType {
    /// Creates a typed rate from a runtime one, if it is between this type's currencies.
    ///
    /// Currencies match only when code and scale both do. The currency converted from is checked
    /// first, so a rate wrong on both sides reports that one.
    ///
    /// ```swift
    /// let eurGbp = try FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(rate)   // throws unless `rate` is EUR to GBP
    /// ```
    ///
    /// - Parameter rate: The rate whose currencies are only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `rate` converts from a currency other
    ///   than `From`, with `From`'s as `lhs`; otherwise if it converts to one other than `To`, with
    ///   `To`'s as `lhs`.
    @inlinable
    init(_ rate: FX.ExchangeRate) throws(MoneyError) {
        try AnyCurrency.requireMatch(From.currency, rate.fromStorage)
        try AnyCurrency.requireMatch(To.currency, rate.toStorage)

        self.init(unchecked: rate.minorPerMinorRate, fromStorage: .implied, toStorage: .implied)
    }
}
