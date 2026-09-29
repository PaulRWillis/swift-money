/// Why a range could not be built: its lower bound is above its upper bound.
///
/// Both bounds are kept, in the order they were given, so a caller can report what arrived.
public struct InvertedBoundsError<C: CurrencyRepresentation>: Error, Equatable, Hashable, Sendable {
    /// The bound given as the lower one, which is above ``upperBound``.
    public let lowerBound: MoneyOf<C>

    /// The bound given as the upper one, which is below ``lowerBound``.
    public let upperBound: MoneyOf<C>

    // Not public: only a range builder that has found the bounds inverted reports one.
    @inlinable
    init(
        lowerBound: MoneyOf<C>,
        upperBound: MoneyOf<C>
    ) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}
