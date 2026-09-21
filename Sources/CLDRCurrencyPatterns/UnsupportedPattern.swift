/// A shape in a locale's CLDR currency patterns that the generator cannot represent, so the locale is
/// refused rather than emitted with output that is quietly wrong.
///
/// CLDR publishes a second pattern, `alphaNextToNumber`, for the case where the currency is written with
/// a letter next to the digits: an ISO code used as a fallback symbol, or a symbol like `US$`. The
/// generated tables hold one pattern per locale and resolve the gap beside the currency per symbol, so a
/// locale whose two patterns differ only in that gap is represented exactly. One that rearranges itself
/// is not.
public enum UnsupportedPattern: Equatable, Sendable {
    /// The currency moves to the other side of the digits, as in `#,##0.00¤` against `¤ #,##0.00`.
    case currencyMovesForLetterSymbols

    /// The digits are grouped differently, as where a locale drops Indian grouping for Western.
    case groupingChangesForLetterSymbols

    /// The two differ some other way, carried here so a report can show what was read.
    case unmodelled(pattern: String, letterSymbolPattern: String)
}

public extension UnsupportedPattern {
    /// Why a locale's pair of currency patterns cannot be represented, or `nil` when it can.
    ///
    /// - Parameters:
    ///   - pattern: A locale's currency pattern, either its `standard` one or its `accounting` one.
    ///   - letterSymbolPattern: The variant CLDR publishes for a currency written with a letter next to
    ///     the digits, its `alphaNextToNumber` twin. No variant at all, one identical to `pattern`, or
    ///     one differing only in spacing is representable: the gap beside the currency is resolved per
    ///     symbol at generation time either way.
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

    // Spacing is what the two patterns are allowed to differ by, so it is what a comparison drops. Every
    // gap CLDR writes here is a space of some width, and all of them are whitespace; a directional mark
    // is not, and a pattern that adds one is reported rather than passed over.
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
