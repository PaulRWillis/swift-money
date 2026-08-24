import SwiftMoney

/// Why localized text could not become an amount.
///
/// Three causes with three remedies, reported apart so a caller is not told to write fewer
/// decimals when the currency is the problem. Parsing bad data throws; it never traps, and
/// it never rounds.
public enum MoneyParsingError: Error, Equatable, Sendable {
    /// The text is not an amount in the style's locale.
    case unrecognizedText(String)

    /// The text is finer than the currency divides, and rounding would lose money quietly.
    case inexactAmount(Currency)

    /// The text is an amount too large to store.
    case unrepresentableAmount(Currency)
}
