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
}
