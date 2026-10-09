public extension FX {
    /// Why a market quote's text is not an exchange rate.
    ///
    /// ```swift
    /// do throws(FX.ExchangeRateParsingError) {
    ///     let rate = try FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(string: text)
    /// } catch {
    ///     switch error {
    ///     case .unrecognizedText: …
    ///     case .notPositive: …
    ///     case let .inexactRate(maximumFractionDigits): …   // round the quote to that many places
    ///     case .overflow: …
    ///     }
    /// }
    /// ```
    enum ExchangeRateParsingError: Error, Equatable, Hashable, Sendable {
        /// The text is not a plain decimal, such as `"abc"`, `"1/3"` or `"1e3"`.
        case unrecognizedText

        /// The quote is zero or negative.
        case notPositive

        /// The quote has more decimal places than a rate between the two currencies holds, with the
        /// most it holds.
        case inexactRate(maximumFractionDigits: Int)

        /// The quote is too large to hold.
        case overflow
    }
}
