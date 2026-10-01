/// Why a range of amounts could not be built from two bounds.
///
/// Bounds of a typed amount share a currency by their type, so for them ``currencyMismatch(_:)``
/// carries `Never` and a `switch` can leave it out. Runtime bounds can arrive in two currencies:
///
/// ```swift
/// do throws(MoneyRangeParsingError<AnyCurrency>) {
///     let limits = try minimum...maximum
/// } catch {
///     switch error {
///     case let .invertedBounds(lowerBound, upperBound): …
///     case let .currencyMismatch(currency): …
///     }
/// }
/// ```
public enum MoneyRangeParsingError<C: CurrencyRepresentation>: Error, Hashable, Sendable {
    /// The bound given as the lower one is above the one given as the upper, with both as given.
    case invertedBounds(lowerBound: MoneyOf<C>, upperBound: MoneyOf<C>)

    /// The bounds are in different currencies, with the upper bound's currency.
    case currencyMismatch(C.Mismatch)
}
