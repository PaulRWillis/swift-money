/// Why an amount could not be rounded onto a set of steps by the rule given.
///
/// Typed amounts share a currency with their steps by their type, so for them
/// ``currencyMismatch(_:)`` carries `Never` and a `switch` can leave it out:
///
/// ```swift
/// do throws(MoneyStepsRoundingError<Currencies.GBP>) {
///     let position = try steps.index(approximating: saved, rounding: .up)
/// } catch {
///     switch error {
///     case .outOfBounds: …   // saved is above the highest step
///     }
/// }
/// ```
///
/// When both apply, ``currencyMismatch(_:)`` is reported.
public enum MoneyStepsRoundingError<C: CurrencyRepresentation>: Error, Hashable, Sendable {
    /// No step satisfies the rule: the amount is beyond the steps, and the only step beside it is
    /// on the side the rule rules out, such as an amount above the highest step under `.up`.
    case outOfBounds

    /// The amount is in another currency than the steps, with the amount's currency.
    case currencyMismatch(C.Mismatch)
}
