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
    /// To recover a typed value, use ``AnyMoney/asMoney(_:)``.
    public var erased: AnyMoney {
        AnyMoney(self)
    }
}

extension AnyMoney {
    /// Returns a typed `Money` value if this instance's currency matches the
    /// given currency type, otherwise `nil`.
    ///
    /// ```swift
    /// let any = Money<GBP>(minorUnits: 500).erased
    /// let typed: Money<GBP>? = any.asMoney(GBP.self)  // Money<GBP>(500)
    /// let wrong: Money<EUR>? = any.asMoney(EUR.self)   // nil
    /// ```
    ///
    /// - Parameter currency: The expected currency type.
    /// - Returns: A `Money<C>` with the same ``minorUnits`` if the currency
    ///   codes match, otherwise `nil`.
    public func asMoney<C: Currency>(_ currency: C.Type) -> Money<C>? {
        guard currencyCode == C.code else { return nil }
        return Money<C>(_unchecked: minorUnits)
    }
}
