/// A count of fraction digits to show, never negative.
///
/// ```swift
/// let length: FractionLength = 2    // fine
/// let bad: FractionLength = -1      // traps
/// ```
public struct FractionLength: Equatable, Hashable, Sendable {
    @usableFromInline
    let rawValue: Int

    /// Creates a fraction length, or `nil` if `value` is negative.
    public init?(exactly value: Int) {
        guard value >= 0 else {
            return nil
        }

        self.rawValue = value
    }
}

extension FractionLength: ExpressibleByIntegerLiteral {
    /// Creates a fraction length from an integer literal.
    ///
    /// A literal is written in source, so a negative one is a programmer mistake and traps. Use
    /// ``init(exactly:)`` for a value taken from data.
    ///
    /// - Precondition: `value` is at least zero.
    public init(integerLiteral value: Int) {
        guard let length = Self(exactly: value) else {
            preconditionFailure("A fraction length must not be negative. Value: \(value)")  // coverage:ignore
        }

        self = length
    }
}

public extension Int {
    /// The number of fraction digits.
    init(_ length: FractionLength) {
        self = length.rawValue
    }
}
