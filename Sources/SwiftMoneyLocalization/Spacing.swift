/// The gap a locale writes between an amount and the currency name beside it.
///
/// The four are the only gaps CLDR uses for that join, so a locale needing any other is refused
/// rather than written out wrongly.
package enum Spacing: Equatable, Sendable {
    /// No gap at all, as Japanese writes it.
    case none

    /// A plain space.
    case asciiSpace

    /// A space that no line break may fall on.
    case nonBreakingSpace

    /// A narrower space that no line break may fall on.
    case narrowNonBreakingSpace

    /// The characters this gap is written with.
    package var rendered: String {
        switch self {
        case .none: ""
        case .asciiSpace: " "
        case .nonBreakingSpace: "\u{00A0}"
        case .narrowNonBreakingSpace: "\u{202F}"
        }
    }

    /// Creates the gap written as `text`.
    ///
    /// - Returns: `nil` if `text` is not one of the gaps CLDR uses for this join.
    package init?(rendering text: String) {
        switch text {
        case "": self = .none
        case " ": self = .asciiSpace
        case "\u{00A0}": self = .nonBreakingSpace
        case "\u{202F}": self = .narrowNonBreakingSpace
        default: return nil
        }
    }
}
