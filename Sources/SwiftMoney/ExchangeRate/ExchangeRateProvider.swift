/// A source of typed exchange rates between currency pairs.
///
/// Implement this protocol to supply rates from any source — a database,
/// a network cache, a hard-coded table for testing, etc. The protocol is
/// intentionally synchronous; callers that need asynchronous rate fetching
/// should refresh rates on a background task and vend the latest cached values
/// here.
///
/// ```swift
/// struct FixedRates: ExchangeRateProvider {
///     func rate<From, To>(
///         from: From.Type, to: To.Type
///     ) -> ExchangeRate<From, To>? {
///         if From.self == GBP.self, To.self == USD.self {
///             return ExchangeRate(from: 100, to: 135)
///         }
///         return nil
///     }
/// }
/// ```
///
/// Used by ``MoneyBag/total(in:using:rounding:)`` to convert each accumulated
/// currency into a single target currency.
public protocol ExchangeRateProvider: Sendable {

    /// Returns the exchange rate for converting `From` to `To`, or `nil` if the
    /// rate is unavailable.
    ///
    /// When `From` and `To` are the same currency, implementations should
    /// return an identity rate `ExchangeRate(from: 1, to: 1)` rather than `nil`,
    /// unless the provider intentionally rejects same-currency pairs.
    ///
    /// - Parameters:
    ///   - from: The source currency type.
    ///   - to:   The target currency type.
    func rate<From: Currency, To: Currency>(
        from: From.Type,
        to: To.Type
    ) -> ExchangeRate<From, To>?
}
