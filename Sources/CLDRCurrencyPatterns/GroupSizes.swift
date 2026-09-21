/// How a locale groups the digits of an amount: how many digits sit in the group nearest the decimal
/// separator, and how many in each group beyond it.
///
/// The two differ in the Indian system, where `#,##,##0.00` groups three digits and then twos.
public struct GroupSizes: Equatable, Sendable {
    /// The group nearest the decimal separator.
    public let primary: Int

    /// Each group beyond the first, which equals ``primary`` in every locale that groups evenly.
    public let secondary: Int

    public init(primary: Int, secondary: Int) {
        self.primary = primary
        self.secondary = secondary
    }
}

public extension GroupSizes {
    /// The grouping `pattern` describes.
    ///
    /// The sizes come from the integer subpattern's own groups, so a pattern writing no group separator
    /// reads as a single group the width of its digits rather than as no grouping at all. No CLDR locale
    /// publishes an ungrouped currency pattern, so nothing here reaches that reading; a locale that did
    /// would need the engine's `.none` grouping, which the generated tables never emit.
    ///
    /// - Parameter pattern: A CLDR number or currency pattern, such as `¤#,##0.00`.
    init(pattern: String) {
        let positive = pattern.split(separator: ";").first ?? Substring(pattern)

        // The integer subpattern alone: the digits before the decimal separator, with the currency,
        // the spacing and any literal text dropped, split on the group separator.
        let integer = positive.prefix { $0 != "." }.filter { $0 == "#" || $0 == "0" || $0 == "," }
        let groups = integer.split(separator: ",", omittingEmptySubsequences: false).map(\.count)

        let primary = groups.last ?? 3

        self.init(
            primary: primary,
            secondary: groups.count >= 3 ? groups[groups.count - 2] : primary
        )
    }
}
