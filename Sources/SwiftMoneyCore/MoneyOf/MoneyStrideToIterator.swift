/// An iterator over the amounts of a ``MoneyStrideTo``.
///
/// Stepping an iterator leaves the sequence it came from intact.
public struct MoneyStrideToIterator<C: CurrencyRepresentation>: IteratorProtocol, Sendable {
    /// The currency of every amount returned.
    @usableFromInline
    let currency: C.Storage

    /// The positions left to return, or `nil` once the last has been returned.
    @usableFromInline
    var remaining: StridePositions?

    /// Creates an iterator over the given positions.
    ///
    /// - Parameters:
    ///   - currency: The currency of every amount returned.
    ///   - remaining: The positions to return, or `nil` for none.
    @inlinable
    init(
        currency: C.Storage,
        remaining: StridePositions?
    ) {
        self.currency = currency
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

        return MoneyOf(unchecked: current.next, storage: currency)
    }
}
