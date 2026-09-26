/// The divisor in a plural rule's `%` term, always at least one.
///
/// ```swift
/// let modulus: PluralModulus = 10    // fine
/// let bad: PluralModulus = 0         // traps
/// ```
package struct PluralModulus: Equatable, Sendable {
    fileprivate let rawValue: UInt64

    /// Creates a modulus, or `nil` if `value` is below one.
    package init?(exactly value: Int) {
        guard value >= 1 else {
            return nil
        }

        self.rawValue = UInt64(value)
    }

    /// Returns what is left of `value` after dividing it by this modulus.
    package func remainder(of value: UInt64) -> UInt64 {
        value % rawValue
    }
}

extension PluralModulus: ExpressibleByIntegerLiteral {
    /// Creates a modulus from an integer literal.
    ///
    /// - Precondition: `value` is at least one.
    package init(integerLiteral value: Int) {
        guard let modulus = Self(exactly: value) else {
            preconditionFailure("A plural modulus must be at least 1. Value: \(value)")  // coverage:ignore
        }

        self = modulus
    }
}

package extension Int {
    init(_ modulus: PluralModulus) {
        self = Int(modulus.rawValue)
    }
}
