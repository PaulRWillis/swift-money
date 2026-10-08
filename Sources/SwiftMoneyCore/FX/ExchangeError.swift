public extension FX {
    /// Why an exchange rate or a conversion could not produce a result.
    ///
    /// ```swift
    /// do throws(FX.ExchangeError) {
    ///     let customer = try mid.applyingMargin(margin)
    /// } catch {
    ///     switch error {
    ///     case .notRepresentable: …   // the customer rate rounds to zero
    ///     }
    /// }
    /// ```
    enum ExchangeError: Error, Equatable, Hashable, Sendable {
        /// A result the library can't hold: too large, or a rate too close to zero to stay positive.
        case notRepresentable
    }
}
