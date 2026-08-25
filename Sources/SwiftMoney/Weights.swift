/// The weights a monetary amount is split by.
///
/// A weight is a non-negative integer, and each weight sizes one part of a split. This type
/// cannot hold an empty list, a negative weight, weights that are all zero, or weights whose
/// sum is not representable, so a split by weights always gives every part a defined share.
public struct Weights: Equatable, Hashable, Sendable {
    fileprivate let values: [Int64]
    fileprivate let sum: Int64

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

// Truncates each part toward zero, then gives the leftover minor units to the parts with the
// largest remainders, one unit of the amount's sign each. This is Hamilton's method: it keeps
// every part as close as an integer can sit to its exact proportional share.
//
// The arithmetic runs on full-width magnitudes, so no product can overflow and no amount, the
// extremes included, can make a split trap.
//
// Not inlinable: the result is already concrete, so there is nothing for a caller to specialize.
@usableFromInline
func split(
    _ amount: Int64,
    by weights: Weights
) -> [Int64] {
    let sign = Sign(of: amount)
    let divisor = UInt64(weights.sum)

    var parts: [Int64] = []
    var remainders: [UInt64] = []
    parts.reserveCapacity(weights.values.count)
    remainders.reserveCapacity(weights.values.count)

    for weight in weights.values {
        guard
            let (quotient, remainder) = WideMagnitude(amount.magnitude, times: UInt64(weight))
                .quotientAndRemainder(dividingBy: divisor),
            let part = Int64(magnitude: quotient, sign: sign)
        else {
            // Unreachable: a weight never passes the sum, so a share never passes the amount.
            preconditionFailure("A share left its amount's range. Amount: \(amount)")
        }

        parts.append(part)
        remainders.append(remainder)
    }

    let leftover = amount - parts.reduce(0, +)

    for index in indicesOfLargestRemainders(remainders, taking: Int(abs(leftover))) {
        parts[index] += amount.signum()
    }

    return parts
}

// The parts with the largest remainders sit farthest below their exact shares, so they receive
// the leftover minor units first. The sort is stable, which Swift guarantees, so equal
// remainders keep part order and the earliest part wins a tie.
private func indicesOfLargestRemainders(
    _ remainders: [UInt64],
    taking count: Int
) -> ArraySlice<Int> {
    let ranked = remainders.indices.sorted { lhs, rhs in
        remainders[lhs] > remainders[rhs]
    }

    return ranked.prefix(count)
}
