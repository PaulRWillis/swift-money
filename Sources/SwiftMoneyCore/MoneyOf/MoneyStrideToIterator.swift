/// An iterator over the amounts of a ``MoneyStrideTo``.
///
/// Stepping an iterator leaves the sequence it came from intact.
public struct MoneyStrideToIterator<C: CurrencyRepresentation>: IteratorProtocol, Sendable {
    /// The amounts left to return, or `nil` once the last has been returned.
    @usableFromInline
    var remaining: MoneyOf<C>.StrideProgression?

    /// Creates an iterator over the given amounts.
    ///
    /// - Parameter remaining: The amounts to return, or `nil` for none.
    @inlinable
    init(remaining: MoneyOf<C>.StrideProgression?) {
        self.remaining = remaining
    }

    /// Advances to the next amount and returns it.
    ///
    /// - Returns: The next amount, or `nil` once the last has been returned.
    @inlinable
    public mutating func next() -> MoneyOf<C>? {
        guard let current = remaining else {
            return nil
        }

        remaining = current.advanced

        return current.first
    }
}
