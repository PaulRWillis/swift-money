/// Which side of the digits a locale writes the currency on.
public enum CurrencySide: Equatable, Sendable {
    /// Before the digits, as in `¤#,##0.00`.
    case leading

    /// After them, as in `#,##0.00 ¤`.
    case trailing
}

public extension CurrencySide {
    // The characters CLDR writes the number itself with. A pattern's spacing and literals are whatever
    // sits outside them.
    private static let numberCharacters: Set<Character> = ["#", "0", ",", "."]

    /// The side `pattern` writes the currency on.
    ///
    /// Only the positive subpattern is read. A negative subpattern, after a `;`, arranges the sign
    /// rather than the currency, and CLDR publishes none that moves the currency to the other side.
    ///
    /// - Parameter pattern: A CLDR currency pattern, such as `¤#,##0.00`.
    /// - Returns: `nil` when the pattern holds no currency placeholder or no digits, which is not a
    ///   pattern CLDR publishes.
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
