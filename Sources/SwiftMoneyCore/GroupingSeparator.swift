/// The string written between digit groups, such as `","`, `"."`, or a narrow no-break space.
///
/// ```swift
/// let separator: GroupingSeparator = ","
/// ```
@usableFromInline
package struct GroupingSeparator: Equatable, Hashable, Sendable {
    @usableFromInline
    let rawValue: String

    /// Creates a grouping separator, or `nil` if `value` is empty.
    package init?(_ value: String) {
        guard !value.isEmpty else {
            return nil
        }

        self.rawValue = value
    }
}

extension GroupingSeparator: ExpressibleByStringLiteral {
    /// Creates a grouping separator from a string literal, trapping on an empty literal.
    @usableFromInline
    package init(stringLiteral value: String) {
        guard let separator = Self(value) else {
            preconditionFailure("A grouping separator must not be empty.")  // coverage:ignore
        }

        self = separator
    }
}
