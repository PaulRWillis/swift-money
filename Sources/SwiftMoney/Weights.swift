/// The weights a monetary amount is split by.
///
/// A weight is a non-negative integer, and each weight sizes one part of a split. This type
/// cannot hold an empty list, a negative weight, or weights that are all zero, so a split by
/// weights always gives every part a defined share.
public struct Weights: Equatable, Hashable, Sendable {
    private let values: [Int64]

    /// Creates weights from values that may not be valid.
    ///
    /// - Parameter weights: The weight of each part, in part order.
    /// - Returns: `nil` if `weights` is empty, contains a negative value, or sums to zero.
    public init?(exactly weights: [Int]) {
        guard
            weights.isEmpty == false,
            weights.allSatisfy({ $0 >= 0 }),
            weights.contains(where: { $0 > 0 })
        else {
            return nil
        }

        self.values = weights.map(Int64.init)
    }
}
