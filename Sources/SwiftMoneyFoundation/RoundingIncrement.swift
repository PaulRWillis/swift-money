/// The step a format style rounds a displayed amount to.
///
/// Counted in the currency's smallest units, so a five-centime rounding is `5` whatever the
/// currency's scale turns out to be. Always at least one: a step of zero or less has no
/// meaning, so those values cannot be constructed.
public struct RoundingIncrement: Equatable, Hashable, Sendable {
    fileprivate let rawValue: Int64

    /// Creates a rounding increment from a value that may not be valid.
    ///
    /// - Parameter value: The step, counted in the currency's smallest units.
    /// - Returns: `nil` if `value` is less than one.
    public init?(exactly value: Int64) {
        guard value >= 1 else {
            return nil
        }

        self.rawValue = value
    }
}

extension RoundingIncrement: ExpressibleByIntegerLiteral {
    /// Creates a rounding increment from an integer literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so a literal below
    /// one is a mistake in the source rather than bad input: it traps instead of failing
    /// gracefully. Use ``init(exactly:)`` for any value that is not a literal.
    ///
    /// ```swift
    /// let step: RoundingIncrement = 5    // fine
    /// let none: RoundingIncrement = 0    // traps
    /// ```
    ///
    /// - Parameter value: The step, counted in the currency's smallest units.
    /// - Precondition: `value` is at least one.
    public init(integerLiteral value: Int64) {
        guard let increment = Self(exactly: value) else {
            preconditionFailure("A rounding increment must be at least 1. Value: \(value)")
        }

        self = increment
    }
}

public extension Int64 {
    /// Creates an integer from a rounding increment.
    ///
    /// - Parameter increment: The rounding increment to convert.
    init(_ increment: RoundingIncrement) {
        self = increment.rawValue
    }
}
