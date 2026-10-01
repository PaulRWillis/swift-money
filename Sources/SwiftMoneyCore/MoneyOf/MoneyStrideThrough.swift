// The amounts from a start up to an end, one stride apart, including the end only if a step lands on
// it: what `stride(from:through:by:)` returns for amounts.
//
// The amounts the standard library's `StrideThroughIterator` returns, stepping the minor units by an
// amount rather than an `Int` for the reason `MoneyStrideTo` gives, and with its last amount found
// once, as there.
//
// Named `MoneyStrideThrough` to mirror the standard library's `StrideThrough`, the way `MoneyRange`
// mirrors `Range`.
@usableFromInline
struct MoneyStrideThrough<C: CurrencyRepresentation>: Sequence, IteratorProtocol, Sendable {
    /// The currency of every amount returned.
    @usableFromInline
    let currency: C.Storage

    /// The positions left to return, or `nil` once the last has been returned or when the start is
    /// past the end.
    @usableFromInline
    var positions: StridePositions?

    @inlinable
    init(
        from start: MoneyOf<C>,
        through end: MoneyOf<C>,
        by stride: MoneyOf<C>.Stride
    ) {
        let first = start.minorUnits
        // A stride is never zero.
        let step = NonZeroInt64(unchecked: stride.amount.minorUnits)
        let ascending = step.rawValue > 0

        // At or before the end, the distance to it is below 2⁶⁴, so `UInt64` holds it, and a whole
        // number of strides within it lands on an amount: wrapping arithmetic finds it exactly.
        let distance = UInt64(bitPattern: ascending ? end.minorUnits &- first : first &- end.minorUnits)
        let travel = (distance / step.rawValue.magnitude) &* step.rawValue.magnitude
        let hasAmounts = ascending ? first <= end.minorUnits : first >= end.minorUnits
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

    // Answers exactly from the positions, so `contains(_:)` never steps through the amounts.
    @inlinable
    func _customContainsEquatableElement(_ element: MoneyOf<C>) -> Bool? {
        guard let positions else {
            return false
        }

        return element.storage == currency && positions.contains(element.minorUnits)
    }
}
