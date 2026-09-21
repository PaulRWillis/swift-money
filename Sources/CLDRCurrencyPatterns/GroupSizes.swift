/// How a locale groups the digits of an amount.
///
/// The two sizes differ in the Indian system, where `#,##,##0.00` groups three digits and then twos.
public struct GroupSizes: Equatable, Sendable {
    /// The group nearest the decimal separator.
    public let primary: Int

    /// Each group beyond that one.
    public let secondary: Int

    public init(primary: Int, secondary: Int) {
        self.primary = primary
        self.secondary = secondary
    }
}

public extension GroupSizes {
    /// The grouping `pattern` describes.
    ///
    /// A pattern writing no group separator reads as one group the width of its digits, rather than as
    /// no grouping at all. No CLDR locale publishes one.
    ///
    /// - Parameter pattern: A CLDR number or currency pattern, such as `¤#,##0.00`.
    init(pattern: String) {
        let positive = pattern.split(separator: ";").first ?? Substring(pattern)

        // The integer subpattern alone, split on the group separator.
        let integer = positive.prefix { $0 != "." }.filter { $0 == "#" || $0 == "0" || $0 == "," }
        let groups = integer.split(separator: ",", omittingEmptySubsequences: false).map(\.count)

        let primary = groups.last ?? 3

        self.init(
            primary: primary,
            secondary: groups.count >= 3 ? groups[groups.count - 2] : primary
        )
    }
}
