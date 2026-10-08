/// The weights a monetary amount is split by.
///
/// Each weight sizes one part of a split. This type cannot hold an empty list, weights that are all
/// zero, or weights whose sum is not representable, so a split by weights always gives every part a
/// defined share. A single weight is never negative, which ``Weight`` guarantees.
public struct Weights: Equatable, Hashable, Sendable {
    /// The weight of each part, in part order.
    fileprivate let weights: [Weight]

    /// The sum of ``weights``, at least one.
    fileprivate let sum: Int64

    /// The weight of each part, in part order.
    @usableFromInline
    var values: [Weight] {
        weights
    }

    /// Creates weights from a list that may not be valid.
    ///
    /// - Parameter weights: The weight of each part, in part order.
    /// - Returns: `nil` if `weights` is empty, sums to zero, or sums past what an amount can hold.
    public init?(_ weights: [Weight]) {
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

    /// Returns the sum of a list of weights.
    ///
    /// - Parameter weights: The weights to add up.
    /// - Returns: The sum, or `nil` if it passes `Int64.max`.
    /// - Complexity: O(*n*), where *n* is the number of weights.
    private static func sum(of weights: [Weight]) -> Int64? {
        var sum: Int64 = 0

        for weight in weights {
            // A weight is never negative, so the running sum only grows.
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
    /// - Precondition: `weights` is not empty, and its sum is at least one and no more than an
    ///   amount can hold.
    public init(arrayLiteral weights: Weight...) {
        guard let valid = Weights(weights) else {
            preconditionFailure("Weights must be non-empty and sum to what an amount can hold. Weights: \(weights)")  // coverage:ignore — exit-test trap
        }

        self = valid
    }
}

/// Returns each weight's share of an amount, in minor units.
///
/// Truncates each share toward zero, then gives the leftover units to the largest remainders,
/// earliest first (Hamilton's method). No amount makes it trap, the extremes included.
///
/// - Parameters:
///   - amount: The minor units to split.
///   - weights: The weights to split by.
/// - Returns: One share per weight, in weight order, summing to `amount`.
/// - Complexity: O(*n* log *n*), where *n* is the number of weights.
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

    guard leftover != 0 else {
        return parts
    }

    distributeLeftover(abs(leftover), by: amount.signum(), toLargestOf: remainders, in: &parts)

    return parts
}

/// Adds `unit` to each of the `count` parts with the largest remainders.
///
/// A tie goes to the earliest part.
///
/// - Parameters:
///   - count: The number of parts to adjust, at most the number of parts.
///   - unit: The signed unit to add to each adjusted part.
///   - remainders: The remainder of each part's share, in part order.
///   - parts: The shares to adjust, in part order.
/// - Complexity: O(*n* log *n*), where *n* is the number of parts.
private func distributeLeftover(
    _ count: Int64,
    by unit: Int64,
    toLargestOf remainders: [UInt64],
    in parts: inout [Int64]
) {
    // `sorted` is stable, so equal remainders keep their weight order.
    let byLargestRemainder = remainders.indices.sorted { remainders[$0] > remainders[$1] }

    for index in byLargestRemainder.prefix(Int(count)) {
        parts[index] += unit
    }
}
