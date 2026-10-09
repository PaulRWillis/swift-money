public extension FX {
    /// Why an exchange rate or a conversion could not produce a result.
    ///
    /// ```swift
    /// let mid = FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.000000000000000001")!
    /// let margin = FX.Margin(.percent(60))!
    /// do throws(FX.ExchangeError) {
    ///     let customer = try mid.applyingMargin(margin)
    /// } catch {
    ///     switch error {
    ///     case .overflow: …
    ///     case .roundsToZero: …   // the customer rate is too small to keep
    ///     }
    /// }
    /// ```
    enum ExchangeError: Error, Equatable, Hashable, Sendable {
        /// The result is too large to represent.
        case overflow

        /// The result is a rate too close to zero to represent, so it would round to zero.
        case roundsToZero
    }
}
