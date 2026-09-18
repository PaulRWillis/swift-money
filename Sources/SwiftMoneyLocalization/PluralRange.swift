/// A span of whole numbers a plural rule compares against, such as CLDR's `2..4`.
///
/// ```swift
/// PluralRange(1)                                // just 1
/// PluralRange(lowerBound: 2, upperBound: 4)     // 2, 3, or 4
/// ```
package struct PluralRange: Equatable, Sendable {
    private let lowerBound: UInt64
    private let upperBound: UInt64

    /// Creates a range covering one value.
    package init(_ value: UInt64) {
        self.lowerBound = value
        self.upperBound = value
    }

    /// Creates a range covering two bounds and everything between them.
    ///
    /// - Returns: `nil` if `upperBound` is below `lowerBound`.
    package init?(lowerBound: UInt64, upperBound: UInt64) {
        guard lowerBound <= upperBound else {
            return nil
        }

        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    /// Returns whether `value` falls in this range.
    package func contains(_ value: UInt64) -> Bool {
        (lowerBound ... upperBound).contains(value)
    }
}
