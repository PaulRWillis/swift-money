/// Which numbering system to render an amount's digits and separators in.
///
/// ``automatic`` leaves the choice to the locale, rendering in its own default system, so the output is
/// unchanged. ``explicit(_:)`` names a system to impose instead, whatever the locale's default.
public enum NumberingSystemSelection: Equatable, Hashable, Sendable {
    /// Render in the locale's own default numbering system.
    case automatic
    /// Render in the named system, overriding the locale's default.
    case explicit(NumberingSystem)
}
