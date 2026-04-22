#if canImport(Foundation)
import Foundation

// MARK: - Decimal initialiser

extension ExchangeRate {

    /// Creates an exchange rate from a major-unit rate expressed as a `Decimal`.
    ///
    /// `majorUnitRate` expresses how many major units of `To` one major unit of `From`
    /// is worth — the standard presentation used by market data feeds (e.g. x-rates.com).
    /// For example, a GBP/USD rate of `1.35` means £1 converts to $1.35.
    ///
    /// ```swift
    /// // 1 GBP = 1.35 USD
    /// let rate = ExchangeRate<GBP, USD>(majorUnitRate: Decimal(string: "1.35")!)
    /// rate?.convert(Money<GBP>(minorUnits: 100))  // 135 USD cents
    /// ```
    ///
    /// > Warning: Float literals such as `1.35` lose precision because `Decimal` is
    /// > initialised through `Double`. Always pass `Decimal(string: "1.35")!`.
    ///
    /// - Returns: `nil` if `majorUnitRate` is NaN, ≤ 0, or if converting it to a
    ///   `FractionalRate` or scaling it would overflow `Int64`.
    public init?(majorUnitRate: Decimal) {
        guard let rate = FractionalRate(majorUnitRate) else { return nil }
        self.init(majorUnitRate: rate)
    }
}
#endif
