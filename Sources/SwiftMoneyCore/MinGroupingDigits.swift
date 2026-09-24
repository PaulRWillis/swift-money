/// How many whole digits the integer part must have before grouping separators appear, always at least
/// one. A locale that groups as soon as there is more than one group (the common case) has the value one;
/// Slovenian has two, so `1234` stays ungrouped while `12345` becomes `12.345`.
///
/// ```swift
/// let threshold: MinGroupingDigits = 2    // fine
/// let bad: MinGroupingDigits = 0          // traps
/// ```
@usableFromInline
package struct MinGroupingDigits: Equatable, Hashable, Sendable {
    @usableFromInline
    let rawValue: Int

    /// Creates a threshold, or `nil` if `value` is below one.
    package init?(exactly value: Int) {
        guard value >= 1 else {
            return nil
        }

        self.rawValue = value
    }
}

extension MinGroupingDigits: ExpressibleByIntegerLiteral {
    /// Creates a threshold from an integer literal.
    ///
    /// - Precondition: `value` is at least one.
    @usableFromInline
    package init(integerLiteral value: Int) {
        guard let threshold = Self(exactly: value) else {
            preconditionFailure("A min grouping digits must be at least 1. Value: \(value)")  // coverage:ignore
        }

        self = threshold
    }
}
