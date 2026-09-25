/// A difference between a locale's `standard` and `accounting` currency patterns that the generated
/// tables cannot represent.
///
/// A locale's record holds one arrangement: one side for the currency, one grouping, and one gap
/// resolved per symbol. The accounting presentation reuses all three and may only add parentheses
/// around a negative, so a locale that rearranges anything else for accounting would be written out
/// with the standard arrangement and be wrong.
public enum UnsupportedAccountingPattern: Equatable, Sendable {
    /// As Norwegian does, writing `#,##0.00 ¤` but `¤ #,##0.00` for accounting.
    case currencyMovesForAccounting

    /// As Tamil does, writing Indian grouping but Western grouping for accounting.
    case groupingChangesForAccounting

    /// As Punjabi does, writing no gap after the currency but a no-break space for accounting.
    case spacingChangesForAccounting
}

public extension UnsupportedAccountingPattern {
    /// How a locale's accounting pattern departs from its standard one, or `nil` when it does not.
    ///
    /// Parentheses around a negative are not a departure: the tables hold those, and they are the
    /// only thing an accounting pattern is expected to add.
    ///
    /// - Parameters:
    ///   - standard: The locale's `standard` currency pattern.
    ///   - accounting: Its `accounting` pattern.
    init?(standard: String, accounting: String) {
        if CurrencySide(pattern: standard) != CurrencySide(pattern: accounting) {
            self = .currencyMovesForAccounting
        } else if GroupSizes(pattern: standard) != GroupSizes(pattern: accounting) {
            self = .groupingChangesForAccounting
        } else if Self.gap(in: standard) != Self.gap(in: accounting) {
            self = .spacingChangesForAccounting
        } else {
            return nil
        }
    }

    // What a pattern writes between the currency and the digits, which the record holds once for both
    // presentations. Read from the positive arrangement, as the rest of the pattern reading is. A
    // directional mark inside this gap (as Hebrew writes one immediately before its symbol) is zero-width
    // formatting, not a spacing difference, so it is stripped before the two presentations are compared —
    // otherwise a mark carried by only one of them would read as a gap that changed for accounting.
    private static func gap(in pattern: String) -> String? {
        let positive = pattern.split(separator: ";").first ?? Substring(pattern)

        guard
            let side = CurrencySide(pattern: pattern),
            let currency = positive.firstIndex(of: "¤"),
            let firstDigit = positive.firstIndex(where: Self.isNumberCharacter),
            let lastDigit = positive.lastIndex(where: Self.isNumberCharacter)
        else {
            return nil
        }

        let rawGap = side == .leading
            ? String(positive[positive.index(after: currency) ..< firstDigit])
            : String(positive[positive.index(after: lastDigit) ..< currency])

        return rawGap.filter { !Self.isDirectionalMark($0) }
    }

    private static func isNumberCharacter(_ character: Character) -> Bool {
        character == "#" || character == "0" || character == "," || character == "."
    }

    // Left-to-right and right-to-left marks: the two directional formatting characters CLDR writes
    // around a currency pattern.
    private static func isDirectionalMark(_ character: Character) -> Bool {
        character == "\u{200E}" || character == "\u{200F}"
    }
}

extension UnsupportedAccountingPattern: CustomStringConvertible {
    public var description: String {
        switch self {
        case .currencyMovesForAccounting:
            "the currency moves to the other side of the digits in the accounting pattern"
        case .groupingChangesForAccounting:
            "the digits are grouped differently in the accounting pattern"
        case .spacingChangesForAccounting:
            "the gap between the currency and the digits changes in the accounting pattern"
        }
    }
}
