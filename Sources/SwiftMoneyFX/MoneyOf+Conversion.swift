import SwiftMoneyCore

public extension MoneyOf where C: CurrencyType {
    /// Returns this amount converted to another currency at the given rate, keeping the fraction for a
    /// single settling.
    ///
    /// ```swift
    /// let eurGbp = FX.ExchangeRate<Currencies.EUR, Currencies.GBP>("0.87")!
    /// let margin = FX.Margin(.basisPoints(5))!
    /// let gbp = try EUR(minorUnits: 100_00)
    ///     .converted(using: eurGbp.applyingMargin(margin))
    ///     .rounded(.toNearestOrEven)   // one rounding, into GBP
    /// ```
    ///
    /// - Parameter rate: The rate from this amount's currency to `To`.
    /// - Returns: This amount in `To`, unsettled.
    /// - Throws: `FX.ExchangeError.overflow` if the converted amount is too large to represent.
    @inlinable func converted<To>(
        using rate: FX.ExchangeRate<C, To>
    ) throws(FX.ExchangeError) -> MoneyOf<To>.Unrounded {
        try rate.applied(to: self)
    }
}
