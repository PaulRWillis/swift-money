/// Why a set of steps could not be built from untrusted bounds and a step.
///
/// What `Steps(from:through:by:)` throws for typed amounts, so a whole server payload is parsed in
/// one call with one exact error. A switch over it needs no currency case, since typed amounts always
/// share one:
///
/// ```swift
/// do {
///     let steps = try GBP.Steps(from: minimum, through: maximum, by: step)
/// } catch {
///     switch error {
///     case let .invertedBounds(inverted): …
///     case .zeroStride: …
///     case .tooManySteps: …
///     }
/// }
/// ```
///
/// When more than one applies, the first in the order of these cases is reported.
public enum StepsError<C: CurrencyRepresentation>: Error, Equatable, Hashable, Sendable {
    /// The lower bound was above the upper bound.
    case invertedBounds(InvertedBoundsError<C>)

    /// The step was zero, so it would never reach the far bound.
    case zeroStride

    /// There would be more steps than `Int` can count.
    case tooManySteps(TooManyStepsError)
}
