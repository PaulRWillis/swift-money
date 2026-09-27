/// Where a custom currency's symbol sits relative to the digits.
///
/// The default, ``automatic``, follows the locale, so a custom currency reads the way a shipped one
/// does. The other two force a side, for a game-style trailing glyph (`500💎`) the locale would not
/// otherwise produce. A forced side is a departure from the locale's own arrangement: it uses a
/// synthesized layout and a plain minus for negatives, since a caller-chosen side has no CLDR
/// arrangement to inherit.
public enum CurrencySymbolPlacement: Equatable, Hashable, Sendable {
    /// Inherit the locale's currency placement, including its accounting form and directional marks.
    case automatic

    /// Force the symbol before the digits.
    case leading

    /// Force the symbol after the digits.
    case trailing
}
