/// One weight in a weighted split: how large its part is, relative to the others.
///
/// A weight is a whole number that is never negative. Zero is allowed — a part weighted zero simply
/// receives nothing.
///
/// ```swift
/// let weights: Weights = [60, 30, 10]   // three weights
/// ```
public struct Weight: Equatable, Hashable, Sendable {
    let value: Int

    /// Creates a weight from a value that may not be valid.
    ///
    /// - Parameter value: The size of the part, relative to the others.
    /// - Returns: `nil` if `value` is negative.
    public init?(exactly value: Int) {
        guard value >= 0 else {
            return nil
        }

        self.value = value
    }
}

extension Weight: ExpressibleByIntegerLiteral {
    /// Creates a weight from an integer literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so a negative value is a
    /// mistake in the source rather than bad input: it traps instead of failing gracefully. Use
    /// ``init(exactly:)`` for any value that is not a literal.
    ///
    /// ```swift
    /// let weight: Weight = 60    // fine
    /// let refund: Weight = -1    // traps
    /// ```
    ///
    /// - Parameter value: The size of the part, relative to the others.
    /// - Precondition: `value` is not negative.
    public init(integerLiteral value: Int) {
        guard let weight = Weight(exactly: value) else {
            preconditionFailure("A weight cannot be negative. Value: \(value)")
        }

        self = weight
    }
}

public extension Int {
    /// Creates an integer from a weight.
    init(_ weight: Weight) {
        self = weight.value
    }
}
