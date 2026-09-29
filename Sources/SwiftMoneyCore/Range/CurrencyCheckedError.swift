/// Why an operation on runtime amounts failed: their currencies differed, or the operation itself
/// failed.
///
/// A runtime operation throws this where its typed twin throws `Failure`, so the one extra way it can
/// fail, a currency mismatch, sits beside the failure both share. A switch over the caught error is
/// exhaustive, and checked by the compiler:
///
/// ```swift
/// do {
///     let range = try minimum...maximum
/// } catch {
///     switch error {
///     case let .currencyMismatch(lhs, rhs): …
///     case let .failure(inverted): …
///     }
/// }
/// ```
///
/// - Note: Mixing calls that throw different types in one `do` widens the thrown type to `any Error`.
///   Parse a whole payload in one call to keep one exact error.
public enum CurrencyCheckedError<Failure: Error & Hashable & Sendable>: Error, Equatable, Hashable, Sendable {
    /// The amounts were in different currencies.
    ///
    /// `lhs` is the receiver's currency, or the lower bound's, and `rhs` the argument's.
    case currencyMismatch(lhs: Currency, rhs: Currency)

    /// The currencies matched, and the operation failed for its own reason.
    case failure(Failure)
}
