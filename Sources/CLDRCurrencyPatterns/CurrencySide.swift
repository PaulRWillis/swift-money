/// Which side of the digits a locale writes the currency on.
public enum CurrencySide: Equatable, Sendable {
    /// As in `¤#,##0.00`.
    case leading

    /// As in `#,##0.00 ¤`.
    case trailing
}

public extension CurrencySide {
    private static let numberCharacters: Set<Character> = ["#", "0", ",", "."]

    /// The side `pattern` writes the currency on.
    ///
    /// Only the positive subpattern is read: a negative one arranges the sign rather than the currency.
    ///
    /// - Parameter pattern: A CLDR currency pattern, such as `¤#,##0.00`.
    /// - Returns: `nil` when the pattern holds no currency placeholder or no digits.
    init?(pattern: String) {
        let positive = pattern.split(separator: ";").first ?? Substring(pattern)

        guard
            let currency = positive.firstIndex(of: "¤"),
            let firstNumber = positive.firstIndex(where: { Self.numberCharacters.contains($0) })
        else {
            return nil
        }

        self = currency < firstNumber ? .leading : .trailing
    }

    /// Whether a letter touches the number where `symbol` sits on this side of it: the general
    /// category of the boundary scalar — `symbol`'s last when this side is `.leading`, its first when
    /// `.trailing` — decides (`Lu`/`Ll`/`Lt`/`Lm`/`Lo`).
    ///
    /// CLDR arranges a symbol with a letter there (an ISO code, `"US$"`, `"F CFA"`) through its
    /// `alphaNextToNumber` pattern instead of the plain one; a symbol with none (`"€"`, `"£"`) keeps
    /// the plain arrangement.
    func letterTouchesTheNumber(in symbol: String) -> Bool {
        let boundary = self == .leading ? symbol.unicodeScalars.last : symbol.unicodeScalars.first

        // An empty symbol touches no number at all; it has nothing to classify.
        guard let boundary else {
            return false
        }

        switch boundary.properties.generalCategory {
        case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter:
            return true
        default:
            return false
        }
    }
}
