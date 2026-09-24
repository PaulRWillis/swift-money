/// Something in a locale's number format that the generated tables cannot represent.
///
/// These are read before the pattern itself, because the pattern reader answers a narrower question
/// and would pass over them without noticing: it looks only between the currency placeholder and the
/// nearest digit.
public enum UnsupportedNumberFormat: Equatable, Sendable {
    /// The locale writes amounts in digits other than `0` to `9`, as Arabic-Indic and Devanagari do.
    case nonLatinDigits(numberingSystem: String)

    /// The pattern carries a directional mark, which places text the affixes have no slot for.
    case directionalMark(pattern: String)
}

public extension UnsupportedNumberFormat {
    /// What a locale's number format publishes that cannot be represented, or `nil` when it can.
    ///
    /// The non-Latin-digit case (``nonLatinDigits(numberingSystem:)``) is not decided here: whether a
    /// numbering system's glyphs can be rendered is settled by the generator against the digit-set data,
    /// not by the pattern. This reads only the `standard` pattern of the system actually in use.
    ///
    /// - Parameter standardPattern: The locale's `standard` currency pattern, from its default numbering
    ///   system.
    init?(standardPattern: String) {
        guard standardPattern.contains(where: Self.isDirectionalMark) else {
            return nil
        }

        self = .directionalMark(pattern: standardPattern)
    }

    // Left-to-right and right-to-left marks. They carry no width, so a pattern holding one looks
    // identical to a pattern without.
    private static func isDirectionalMark(_ character: Character) -> Bool {
        character == "\u{200E}" || character == "\u{200F}"
    }
}

extension UnsupportedNumberFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nonLatinDigits(let numberingSystem):
            "amounts are written in the \(numberingSystem) digits rather than 0 to 9"
        case .directionalMark(let pattern):
            "the standard pattern carries a directional mark: \(pattern)"
        }
    }
}
