extension FX.ExchangeRate {
    /// Returns an amount converted to `To` at this rate, keeping the fraction for a single settling.
    ///
    /// ```swift
    /// let eurGbp = FX.ExchangeRate<Currencies.EUR, Currencies.GBP>("0.87")!
    /// let gbp = try eurGbp.applied(to: EUR(minorUnits: 100_00))
    ///     .rounded(.toNearestOrEven)   // £87.00
    /// ```
    ///
    /// - Parameter amount: The amount to convert.
    /// - Returns: `amount` in `To`, unsettled.
    /// - Throws: ``FX/ExchangeError/overflow`` if the converted amount is too large to represent.
    @inlinable package func applied(
        to amount: MoneyOf<From>
    ) throws(FX.ExchangeError) -> MoneyOf<To>.Unrounded {
        // An `Int64` amount at a realistic rate fits one 64-by-128-bit multiply; an extreme rate
        // falls back to the 256-bit path.
        if let converted = Fixed.scalingIfRepresentable(amount.minorUnits, by: minorPerMinorRate.value) {
            return MoneyOf<To>.Unrounded(converted, storage: .implied)
        }
        return try applied(to: amount.unrounded)
    }

    /// Returns an unrounded amount converted to `To` at this rate, keeping the fraction for a single
    /// settling.
    ///
    /// ```swift
    /// let eurGbp = FX.ExchangeRate<Currencies.EUR, Currencies.GBP>("0.87")!
    /// let third = Rate(string: "1/3")!
    /// let gbp = try eurGbp.applied(to: EUR(minorUnits: 300_00).unrounded * third)
    ///     .rounded(.toNearestOrEven)   // £87.00
    /// ```
    ///
    /// - Parameter amount: The amount to convert.
    /// - Returns: `amount` in `To`, unsettled.
    /// - Throws: ``FX/ExchangeError/overflow`` if the converted amount is too large to represent.
    @inlinable package func applied(
        to amount: MoneyOf<From>.Unrounded
    ) throws(FX.ExchangeError) -> MoneyOf<To>.Unrounded {
        guard let converted = amount.minorUnits.multipliedIfRepresentable(by: minorPerMinorRate.value) else {
            throw .overflow
        }

        return MoneyOf<To>.Unrounded(converted, storage: .implied)
    }
}
