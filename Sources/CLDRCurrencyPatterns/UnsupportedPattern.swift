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

    // A directional mark is zero-width formatting, not a spacing difference the tables need to
    // represent, so it is filtered out here alongside whitespace: a pattern that only gains a mark
    // beside its letter-symbol variant is representable, the same as one that only gains a space.
    private static func withoutSpacing(_ pattern: String) -> String {
        pattern.filter { !$0.isWhitespace && !Self.isDirectionalMark($0) }
    }

    // Left-to-right and right-to-left marks: the two directional formatting characters CLDR writes
    // around a currency pattern.
    private static func isDirectionalMark(_ character: Character) -> Bool {
        character == "\u{200E}" || character == "\u{200F}"
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
