/// A span of whole numbers a plural rule compares against, such as CLDR's `2..4`.
///
/// ```swift
/// PluralRange(1)          // just 1
/// PluralRange(2 ... 4)    // 2, 3, or 4
/// ```
package struct PluralRange: Equatable, Sendable {
    /// The span of values this range covers.
    package let bounds: ClosedRange<UInt64>

    /// Creates a range covering one value.
    package init(_ value: UInt64) {
        self.bounds = value ... value
    }

    /// Creates a range covering a span of values.
    package init(_ bounds: ClosedRange<UInt64>) {
        self.bounds = bounds
    }

    /// Returns whether `value` falls in this range.
    package func contains(_ value: UInt64) -> Bool {
        bounds.contains(value)
    }
}
