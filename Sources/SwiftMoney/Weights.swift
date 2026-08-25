/// The weights a monetary amount is split by.
///
/// A weight is a non-negative integer, and each weight sizes one part of a split. This type
/// cannot hold an empty list, a negative weight, weights that are all zero, or weights whose
/// sum is not representable, so a split by weights always gives every part a defined share.
public struct Weights: Equatable, Hashable, Sendable {
    private let values: [Int64]
    private let sum: Int64

    /// Creates weights from values that may not be valid.
    ///
    /// - Parameter weights: The weight of each part, in part order.
    /// - Returns: `nil` if `weights` is empty, contains a negative value, sums to zero, or sums
    ///   past what an amount can hold.
    public init?(exactly weights: [Int]) {
        guard
            weights.isEmpty == false,
            weights.allSatisfy({ $0 >= 0 }),
            let sum = Weights.sum(of: weights),
            sum > 0
        else {
            return nil
        }

        self.values = weights.map(Int64.init)
        self.sum = sum
    }

    // nil when the sum passes `Int64.max`, which a split's divisor must not.
    private static func sum(of weights: [Int]) -> Int64? {
        var sum: Int64 = 0

        for weight in weights {
            let (next, overflow) = sum.addingReportingOverflow(Int64(weight))

            guard overflow == false else {
                return nil
            }

            sum = next
        }

        return sum
    }
}

extension Weights: ExpressibleByArrayLiteral {
    /// Creates weights from an array literal.
    ///
    /// ```swift
    /// let weights: Weights = [60, 30, 10]    // fine
    /// let none: Weights = []                 // traps
    /// ```
    ///
    /// - Parameter weights: The weight of each part, in part order.
    /// - Precondition: `weights` is not empty, holds no negative value, and sums between one and
    ///   `Int64.max`.
    public init(arrayLiteral weights: Int...) {
        guard let valid = Weights(exactly: weights) else {
            preconditionFailure(
                "Weights must be non-empty, non-negative, and sum between 1 and Int64.max. Weights: \(weights)"
            )
        }

        self = valid
    }
}
