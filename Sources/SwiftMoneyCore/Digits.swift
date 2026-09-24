/// The digit glyphs a currency amount is rendered with: the ASCII `0` through `9`, or a locale's own set.
///
/// ``ascii`` is a named case, not the absence of a set, so the common path writes a plain byte and never
/// takes a glyph lookup.
@usableFromInline
package enum Digits: Equatable, Hashable, Sendable {
    /// The ASCII digits `0` through `9`, one byte each.
    case ascii

    /// A locale's own ten digit glyphs, as Arabic-Indic and Devanagari use.
    case glyphs(DigitGlyphs)
}

package extension Digits {
    /// How many UTF-8 bytes one rendered digit takes: one for ASCII, the set's uniform width otherwise.
    @inlinable
    var bytesPerDigit: Int {
        switch self {
        case .ascii: 1
        case .glyphs(let glyphs): glyphs.bytesPerDigit
        }
    }
}
