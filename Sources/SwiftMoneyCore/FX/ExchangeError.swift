public extension FX {
    /// Why an exchange rate or a conversion could not produce a result.
    ///
    /// `Mismatch` is what the rate's currencies report on a mismatch: `Never` for typed currencies,
    /// so a `switch` leaves out ``currencyMismatch(_:)``, and ``Currency`` for a runtime rate.
    /// The error is generic over the mismatch alone, since nothing else it carries depends on the
    /// currencies.
    ///
    /// ```swift
    /// let mid = FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.000000000000000001")!
    /// let margin = FX.Margin(.percent(60))!
    /// do throws(FX.ExchangeError<Never>) {
    ///     let customer = try mid.applyingMargin(margin)
    /// } catch {
    ///     switch error {
    ///     case .overflow: …
    ///     case .roundsToZero: …   // the customer rate is too small to keep
    ///     }
    /// }
    /// ```
    enum ExchangeError<Mismatch: Hashable & Sendable>: Error, Hashable, Sendable {
        /// The result is too large to represent.
        case overflow

        /// The result is a rate too close to zero to represent, so it would round to zero.
        case roundsToZero

        /// Two rates that must share a currency do not, with the currency the second one converts
        /// from.
        case currencyMismatch(Mismatch)
    }
}
