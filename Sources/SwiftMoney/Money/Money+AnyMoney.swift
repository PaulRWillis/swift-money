extension Money {
    /// A type-erased copy of this value.
    ///
    /// Use this to store typed `Money<C>` values in heterogeneous collections,
    /// pass across runtime boundaries, or persist via `Codable`:
    ///
    /// ```swift
    /// let arr: [AnyMoney] = [
    ///     Money<GBP>(minorUnits: 500).erased,
    ///     Money<EUR>(minorUnits: 1000).erased,
    /// ]
    /// ```
    ///
    /// To recover a typed value, use ``Money/init(_:)-anyMoney``.
    public var erased: AnyMoney {
        AnyMoney(self)
    }

    /// Creates a typed `Money` value from a type-erased `AnyMoney`, if the
    /// currency matches.
    ///
    /// Returns `nil` when the currency code of `anyMoney` does not match `C`,
    /// or when the stored value is the sentinel minimum.
    ///
    /// ```swift
    /// let any = Money<GBP>(minorUnits: 500).erased
    /// let typed: Money<GBP>? = Money<GBP>(any)   // Money<GBP>(500)
    /// let wrong: Money<EUR>? = Money<EUR>(any)   // nil
    /// ```
    ///
    /// - Parameter anyMoney: The type-erased money value to convert.
    public init?(_ anyMoney: AnyMoney) {
        guard anyMoney.currencyCode == Currency.code else { return nil }
        guard anyMoney.minorUnits != .min else { return nil }
        self.init(minorUnits: anyMoney.minorUnits)
    }
}
