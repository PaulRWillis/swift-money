/// Why a set of steps could not be built from two bounds and a stride.
///
/// Typed amounts share a currency by their type, so for them ``currencyMismatch(_:)`` carries
/// `Never` and a `switch` can leave it out:
///
/// ```swift
/// do throws(MoneyStepsParsingError<Currencies.GBP>) {
///     let steps = try GBP.Steps(from: minimum, through: maximum, by: step)
/// } catch {
///     switch error {
///     case let .invertedBounds(lowerBound, upperBound): …
///     case .zeroStride: …
///     case .tooManySteps: …
///     }
/// }
/// ```
///
/// When more than one applies, the first in the order of these cases is reported.
public enum MoneyStepsParsingError<C: CurrencyRepresentation>: Error, Hashable, Sendable {
    /// The upper bound or the stride is in another currency than the lower bound, with the currency
    /// it is in.
    case currencyMismatch(C.Mismatch)

    /// The bound given as the lower one is above the one given as the upper, with both as given.
    case invertedBounds(lowerBound: MoneyOf<C>, upperBound: MoneyOf<C>)

    /// The stride is zero, so it would never reach the far bound.
    case zeroStride

    /// There would be more steps than `Int` can count.
    ///
    /// Where `Int` is 64 bits, that takes a span of `Int.max` minor units or more, in single-unit
    /// steps. On 32-bit watchOS a range of about £21.4 million in 1p steps is already too many. A
    /// longer stride gives fewer steps.
    case tooManySteps
}
