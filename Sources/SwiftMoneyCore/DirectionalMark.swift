/// A zero-width Unicode formatting mark a locale places around its currency to control text direction,
/// such as Arabic wrapping its pattern in a right-to-left mark.
///
/// The two marks are the whole representable set: an arbitrary scalar cannot become a `DirectionalMark`,
/// so a token carrying one is always one of exactly these two, never an unvalidated code point.
@usableFromInline
package enum DirectionalMark: Equatable, Hashable, Sendable {
    /// U+200E LEFT-TO-RIGHT MARK.
    case leftToRight

    /// U+200F RIGHT-TO-LEFT MARK.
    case rightToLeft

    /// The Unicode scalar this mark renders as, the single named home for the two mark scalars.
    @inlinable
    package var scalar: Unicode.Scalar {
        switch self {
        case .leftToRight: "\u{200E}"
        case .rightToLeft: "\u{200F}"
        }
    }

    /// The mark `scalar` denotes, or `nil` for any other scalar.
    package init?(_ scalar: Unicode.Scalar) {
        switch scalar {
        case "\u{200E}": self = .leftToRight
        case "\u{200F}": self = .rightToLeft
        default: return nil
        }
    }
}
