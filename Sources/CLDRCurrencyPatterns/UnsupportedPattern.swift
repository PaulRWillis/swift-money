/// A shape in a locale's CLDR currency patterns that the generated tables cannot represent.
///
/// CLDR publishes a second pattern, `alphaNextToNumber`, for a currency written with a letter beside the
/// digits. The tables hold one pattern per locale, so a variant that only spaces the currency differently
/// is represented exactly and one that rearranges it is not.
public enum UnsupportedPattern: Equatable, Sendable {
    /// As in `#,##0.00¤` against `¤ #,##0.00`.
    case currencyMovesForLetterSymbols

    /// As where a locale drops Indian grouping for Western.
    case groupingChangesForLetterSymbols

    /// A difference this type does not name, carried so a report can show it.
    case unmodelled(pattern: String, letterSymbolPattern: String)
}

public extension UnsupportedPattern {
    /// Why a locale's pair of currency patterns cannot be represented, or `nil` when it can.
    ///
    /// - Parameters:
    ///   - pattern: A locale's `standard` or `accounting` currency pattern.
    ///   - letterSymbolPattern: Its `alphaNextToNumber` variant. Absent, identical, or differing only in
    ///     spacing is representable, the gap being resolved per symbol either way.
    init?(pattern: String, letterSymbolPattern: String?) {
        guard
            let letterSymbolPattern,
            Self.withoutSpacing(pattern) != Self.withoutSpacing(letterSymbolPattern)
        else {
            return nil
        }

        if CurrencySide(pattern: pattern) != CurrencySide(pattern: letterSymbolPattern) {
            self = .currencyMovesForLetterSymbols
        } else if GroupSizes(pattern: pattern) != GroupSizes(pattern: letterSymbolPattern) {
            self = .groupingChangesForLetterSymbols
        } else {
            self = .unmodelled(pattern: pattern, letterSymbolPattern: letterSymbolPattern)
        }
    }

    // Every gap CLDR writes here is whitespace; a directional mark is not, so a pattern adding one is
    // reported rather than passed over.
    private static func withoutSpacing(_ pattern: String) -> String {
        pattern.filter { !$0.isWhitespace }
    }
}

extension UnsupportedPattern: CustomStringConvertible {
    public var description: String {
        switch self {
        case .currencyMovesForLetterSymbols:
            "the currency moves to the other side of the digits when it is written with letters"
        case .groupingChangesForLetterSymbols:
            "the digits are grouped differently when the currency is written with letters"
        case .unmodelled(let pattern, let letterSymbolPattern):
            "the pattern for a currency written with letters differs in a way this tool does not model: "
                + "\(pattern) against \(letterSymbolPattern)"
        }
    }
}
