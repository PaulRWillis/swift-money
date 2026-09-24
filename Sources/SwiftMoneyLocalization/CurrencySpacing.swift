/// The gap between a custom currency's symbol or name and the digits.
///
/// The default, ``automatic``, reads the gap from the locale, which is what makes a custom currency
/// space like a shipped one. For a symbol it picks between the locale's two currency gaps by the shape
/// of the symbol:
/// - a **glyph** (any symbol not made entirely of ASCII letters and digits) takes the locale's pattern
///   gap, the one it bakes beside every symbol: `💎500.00` in en, `500,00 💎` in de;
/// - an **ASCII letters/digits code** (`GEM`, `XP`, `Cr`) takes the locale's letter gap, the one it
///   inserts only next to a letter-like symbol: `GEM\u{00A0}500.00`.
///
/// For a full name it takes the locale's name-join gap.
///
/// The glyph test is a pure ASCII byte check, so it needs no Unicode tables and runs under Embedded.
/// It therefore only approximates CLDR's boundary rule: a punctuation-boundary symbol (`kr.`) or a
/// non-Latin-letter one (`грн`, `圓`) reads as a glyph and takes the pattern gap, where CLDR's own rule
/// would space it. A caller who needs a different gap sets it with ``fixed(_:)``.
public enum CurrencySpacing: Equatable, Hashable, Sendable {
    /// The locale-appropriate gap for the context: the pattern or letter gap for a symbol, the join gap
    /// for a full name.
    case automatic

    /// An exact gap, whatever the locale would choose: ``Spacing/none`` for a tight `500pts`, or one of
    /// the spaces to force a gap.
    case fixed(Spacing)
}
