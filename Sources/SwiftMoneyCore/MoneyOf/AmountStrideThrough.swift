// The amounts from a start up to an end, one stride apart, including the end only if a step lands on
// it: what `stride(from:through:by:)` returns for amounts.
//
// The standard library's `StrideThroughIterator` logic, over minor units with an `Int64` stride, for
// the reason `AmountStrideTo` gives. Where the standard library keeps a flag for having returned the
// end and an index sentinel for a step that overflowed, this clears `upcoming` in both cases: the same
// amounts, with no pair of fields that could disagree.
@usableFromInline
struct AmountStrideThrough<C: CurrencyRepresentation>: Sequence, IteratorProtocol, Sendable {
    // `nil` once the end has been returned or passed, or a step has left `Int64`.
    @usableFromInline
    var upcoming: Int64?

    @usableFromInline
    let start: Int64

    @usableFromInline
    let end: Int64

    @usableFromInline
    let stride: Int64

    @usableFromInline
    let storage: C.Storage

    @inlinable
    init(
        from start: MoneyOf<C>,
        through end: MoneyOf<C>,
        by stride: MoneyOf<C>.Stride
    ) {
        self.upcoming = start.minorUnits
        self.start = start.minorUnits
        self.end = end.minorUnits
        self.stride = stride.amount.minorUnits
        self.storage = start.storage
    }

    @inlinable
    mutating func next() -> MoneyOf<C>? {
        guard let current = upcoming else {
            return nil
        }
        guard stride > 0 ? current < end : current > end else {
            upcoming = nil
            return current == end ? MoneyOf(unchecked: current, storage: storage) : nil
        }

        let (advanced, overflow) = current.addingReportingOverflow(stride)
        upcoming = overflow ? nil : advanced

        return MoneyOf(unchecked: current, storage: storage)
    }

    // The exact count, as the standard library's stride sequences report, so `Array(_:)` allocates once.
    @inlinable
    var underestimatedCount: Int {
        var remaining = self
        var count = 0

        while remaining.next() != nil {
            count += 1
        }

        return count
    }

    // Rules out an amount outside the span at once, as the standard library does; `nil` makes
    // `contains(_:)` step through the rest.
    @inlinable
    func _customContainsEquatableElement(_ element: MoneyOf<C>) -> Bool? {
        let minorUnits = element.minorUnits
        let outside = stride < 0
            ? minorUnits < end || start < minorUnits
            : minorUnits < start || end < minorUnits

        return outside ? false : nil
    }
}
