// The amounts from a start up to, but not including, an end, one stride apart: what
// `stride(from:to:by:)` returns for amounts.
//
// The standard library's `StrideToIterator` logic, over minor units. `Swift.stride` over `Int64` can't
// be used: `Int64.Stride` is `Int`, 32 bits on watchOS, so a stride above `Int32.max` would trap. Here
// the stride is `Int64` too, and a step that would leave `Int64` ends the sequence, as the standard
// library's signed `_step` does. Its own iterator, since stepping a copy leaves the original intact.
@usableFromInline
struct AmountStrideTo<C: CurrencyRepresentation>: Sequence, IteratorProtocol, Sendable {
    // `nil` once a step has left `Int64`: every later amount is past the end, so none is returned.
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
        to end: MoneyOf<C>,
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
        guard let current = upcoming, stride > 0 ? current < end : current > end else {
            return nil
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
            ? minorUnits <= end || start < minorUnits
            : minorUnits < start || end <= minorUnits

        return outside ? false : nil
    }
}
