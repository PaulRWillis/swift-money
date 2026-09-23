/// Something in a locale's number format that the generated tables cannot represent.
///
/// These are read before the pattern itself, because the pattern reader answers a narrower question
/// and would pass over them without noticing: it looks only between the currency placeholder and the
/// nearest digit.
public enum UnsupportedNumberFormat: Equatable, Sendable {
    /// The locale writes amounts in digits other than `0` to `9`, as Arabic-Indic and Devanagari do.
    case nonLatinDigits(numberingSystem: String)

    /// The standard pattern arranges a negative amount itself, as in `#,##0.00¤;¤-#,##0.00`.
    ///
    /// The affixes can express the arrangement, so the generator reads it for a Latin-script locale.
    /// It raises this only where that is not yet done, currently a non-Latin-script locale.
    case negativeSubpattern(pattern: String)

    /// The pattern carries a directional mark, which places text the affixes have no slot for.
    case directionalMark(pattern: String)

    /// The locale leaves short numbers ungrouped, as Slovenian writes `1234` but `12.345`.
    ///
    /// CLDR calls this `minimumGroupingDigits`. The engine groups by size alone, with no threshold
    /// on how long the number has to be first.
    case groupingThreshold(minimumDigits: Int)
}

public extension UnsupportedNumberFormat {
    /// What a locale's number format publishes that cannot be represented, or `nil` when it can.
    ///
    /// - Parameters:
    ///   - standardPattern: The locale's `standard` currency pattern.
    ///   - defaultNumberingSystem: The numbering system the locale writes amounts in, CLDR's
    ///     `defaultNumberingSystem`.
    ///   - minimumGroupingDigits: How long the integer part must be before the locale groups it at
    ///     all, CLDR's `minimumGroupingDigits`. One means it always groups.
    init?(standardPattern: String, defaultNumberingSystem: String, minimumGroupingDigits: Int) {
        if defaultNumberingSystem != Self.latinDigits {
            self = .nonLatinDigits(numberingSystem: defaultNumberingSystem)
        } else if standardPattern.contains(where: Self.isDirectionalMark) {
            self = .directionalMark(pattern: standardPattern)
        } else if minimumGroupingDigits > 1 {
            self = .groupingThreshold(minimumDigits: minimumGroupingDigits)
        } else {
            return nil
        }
    }

    // CLDR's name for the digits 0 to 9.
    private static let latinDigits = "latn"

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
        case .negativeSubpattern(let pattern):
            "the standard pattern arranges a negative amount itself: \(pattern)"
        case .directionalMark(let pattern):
            "the standard pattern carries a directional mark: \(pattern)"
        case .groupingThreshold(let minimumDigits):
            "the integer part is left ungrouped below \(minimumDigits) grouping digits"
        }
    }
}
