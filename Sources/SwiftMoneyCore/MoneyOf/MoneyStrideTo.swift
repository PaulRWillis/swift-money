// The amounts from a start up to, but not including, an end, one stride apart: what
// `stride(from:to:by:)` returns for amounts.
//
// The amounts the standard library's `StrideToIterator` returns, stepping the minor units.
// `Swift.stride` over `Int64` can't be used: `Int64.Stride` is `Int`, 32 bits on watchOS, so a stride
// above `Int32.max` would trap. Here the stride is an amount, as wide as the amounts it steps. Its own
// iterator, since stepping a copy leaves the original intact.
//
// The last amount is found once, by a division, so a step only compares with it. Comparing with the end
// instead costs every step a test of the stride's sign and a check that the step stays in `Int64`.
//
// Named `MoneyStrideTo` to mirror the standard library's `StrideTo`, the way `MoneyRange` mirrors
// `Range`.
@usableFromInline
struct MoneyStrideTo<C: CurrencyRepresentation>: Sequence, IteratorProtocol, Sendable {
    /// The currency of every amount returned.
    @usableFromInline
    let currency: C.Storage

    /// The positions left to return, or `nil` once the last has been returned or when no amount
    /// lies before the end.
    @usableFromInline
    var positions: StridePositions?

    @inlinable
    init(
        from start: MoneyOf<C>,
        to end: MoneyOf<C>,
        by stride: MoneyOf<C>.Stride
    ) {
        let first = start.minorUnits
        // A stride is never zero.
        let step = NonZeroInt64(unchecked: stride.amount.minorUnits)
        let ascending = step.rawValue > 0

        // Before the end, the distance to it is at least one and below 2⁶⁴, so `UInt64` holds it, and a
        // whole number of strides short of it lands on an amount: wrapping arithmetic finds it exactly.
        let distance = UInt64(bitPattern: ascending ? end.minorUnits &- first : first &- end.minorUnits)
        let travel = ((distance &- 1) / step.rawValue.magnitude) &* step.rawValue.magnitude
        let hasAmounts = ascending ? first < end.minorUnits : first > end.minorUnits
        let last = ascending ? first &+ Int64(bitPattern: travel) : first &- Int64(bitPattern: travel)

        self.currency = start.storage
        self.positions = hasAmounts ? StridePositions(next: first, last: last, step: step) : nil
    }

    @inlinable
    mutating func next() -> MoneyOf<C>? {
        guard let current = positions else {
            return nil
        }

        positions = current.advanced

        return MoneyOf(unchecked: current.next, storage: currency)
    }

    // The exact count, as the standard library's stride sequences report, so `Array(_:)` allocates once.
    @inlinable
    var underestimatedCount: Int {
        guard let positions else {
            return 0
        }

        return positions.count
    }

    // Rules out an amount outside the span at once, as the standard library does; `nil` makes
    // `contains(_:)` step through the rest.
    @inlinable
    func _customContainsEquatableElement(_ element: MoneyOf<C>) -> Bool? {
        guard let positions else {
            return false
        }

        let minorUnits = element.minorUnits
        let outside = positions.step.rawValue < 0
            ? minorUnits < positions.last || positions.next < minorUnits
            : minorUnits < positions.next || positions.last < minorUnits

        return outside ? false : nil
    }
}
