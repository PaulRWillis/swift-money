/// The way a step moves through amounts: up toward larger ones, or down toward smaller ones.
@usableFromInline
enum StrideDirection: Sendable {
    /// Toward larger amounts, from the lower bound to the upper.
    case upward

    /// Toward smaller amounts, from the upper bound to the lower.
    case downward

    /// Creates the direction a step moves in, from its sign.
    ///
    /// - Parameter step: The minor units each step moves by.
    @inlinable
    init(of step: NonZero<Money.MinorUnits>) {
        self = step.rawValue > 0 ? .upward : .downward
    }
}
