/// The weights a monetary amount is split by.
///
/// Each weight sizes one part of a split. This type cannot hold an empty list, weights that are all
/// zero, or weights whose sum is not representable, so a split by weights always gives every part a
/// defined share. A single weight is never negative, which ``Weight`` guarantees.
public struct Weights: Equatable, Hashable, Sendable {
    fileprivate let weights: [Weight]
    fileprivate let sum: Int64

    /// The weight of each part, in part order.
    var values: [Weight] {
        weights
    }

    /// Creates weights from values that may not be valid.
    ///
    /// - Parameter weights: The weight of each part, in part order.
    /// - Returns: `nil` if `weights` is empty, sums to zero, or sums past what an amount can hold.
    public init?(exactly weights: [Weight]) {
        guard
            weights.isEmpty == false,
            let sum = Weights.sum(of: weights),
            sum > 0
        else {
            return nil
        }

        self.weights = weights
        self.sum = sum
    }

    // nil when the sum passes `Int64.max`, which a split's divisor must not. A weight is never
    // negative, so the running sum only grows.
    private static func sum(of weights: [Weight]) -> Int64? {
        var sum: Int64 = 0

        for weight in weights {
            let (next, overflow) = sum.addingReportingOverflow(Int64(Int(weight)))

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
    /// - Precondition: `weights` is not empty, and its sum is at least one and no more than an amount
    ///   can hold.
    public init(arrayLiteral weights: Weight...) {
        guard let valid = Weights(exactly: weights) else {
            preconditionFailure("Weights must be non-empty and sum to what an amount can hold. Weights: \(weights)")  // coverage:ignore — exit-test trap
        }

        self = valid
    }
}

// Truncates each part toward zero, then gives the leftover minor units to the parts with the
// largest remainders, one unit of the amount's sign each. This is Hamilton's method: each part
// differs from its exact proportional share by less than one unit, and no split that conserves
// the amount has a smaller total difference.
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
            let (quotient, remainder) = WideMagnitude(amount.magnitude, times: UInt64(Int(weight)))
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

// The parts with the largest remainders sit farthest from their exact shares, by magnitude, so
// they receive the leftover minor units first. The sort is stable, which Swift guarantees, so
// equal remainders keep part order and the earliest part wins a tie.
private func indicesOfLargestRemainders(
    _ remainders: [UInt64],
    taking count: Int
) -> ArraySlice<Int> {
    let ranked = remainders.indices.sorted { lhs, rhs in
        remainders[lhs] > remainders[rhs]
    }

    return ranked.prefix(count)
}
