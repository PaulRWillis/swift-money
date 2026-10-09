import SwiftMoneyCore

public extension MoneyOf.Unrounded where C: CurrencyType {
    /// Returns this amount converted to another currency at the given rate, keeping the fraction for a
    /// single settling.
    ///
    /// Converting leaves the result unsettled, so a chain of conversions rounds once at the end rather
    /// than at each hop.
    ///
    /// ```swift
    /// let eurGbp = FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.87")!
    /// let third = Rate(string: "1/3")!
    /// let gbp = try (EUR(minorUnits: 300_00).unrounded * third)
    ///     .converted(using: eurGbp)
    ///     .rounded(.toNearestOrEven)   // £87.00
    /// ```
    ///
    /// - Parameter rate: The rate from this amount's currency to `To`.
    /// - Returns: This amount in `To`, unsettled.
    /// - Throws: `FX.ExchangeError.overflow` if the converted amount is too large to represent.
    @inlinable func converted<To>(
        using rate: FX.ExchangeRateOf<C, To>
    ) throws(FX.ExchangeError) -> MoneyOf<To>.Unrounded {
        try rate.applied(to: self)
    }
}
