/// The number of whole digits in a group, always at least one.
///
/// ```swift
/// let size: GroupingSize = 3    // fine
/// let bad: GroupingSize = 0     // traps
/// ```
@usableFromInline
package struct GroupingSize: Equatable, Hashable, Sendable {
    @usableFromInline
    let rawValue: Int

    /// Creates a grouping size, or `nil` if `value` is below one.
    package init?(exactly value: Int) {
        guard value >= 1 else {
            return nil
        }

        self.rawValue = value
    }
}

extension GroupingSize: ExpressibleByIntegerLiteral {
    /// Creates a grouping size from an integer literal.
    ///
    /// - Precondition: `value` is at least one.
    @usableFromInline
    package init(integerLiteral value: Int) {
        guard let size = Self(exactly: value) else {
            preconditionFailure("A grouping size must be at least 1. Value: \(value)")  // coverage:ignore
        }

        self = size
    }
}
