// The amounts from a start up to an end, one stride apart, including the end only if a step lands on
// it: what `stride(from:through:by:)` returns for amounts.
//
// The amounts the standard library's `StrideThroughIterator` returns, over minor units with an `Int64`
// stride, for the reason `MoneyStrideTo` gives, and with its last amount found once, as there.
//
// Named `MoneyStrideThrough` to mirror the standard library's `StrideThrough`, the way `MoneyRange`
// mirrors `Range`.
@usableFromInline
struct MoneyStrideThrough<C: CurrencyRepresentation>: Sequence, IteratorProtocol, Sendable {
    // `nil` once `last` has been returned, or from the start when the start is past the end.
    @usableFromInline
    var upcoming: Int64?

    // The final amount returned: the end if a step lands on it. Every amount from `start` to here is
    // at or before the end, so fits `Int64`.
    @usableFromInline
    let last: Int64

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
        let first = start.minorUnits
        let step = stride.amount.minorUnits
        let ascending = step > 0

        // At or before the end, the distance to it is below 2⁶⁴, so `UInt64` holds it, and a whole
        // number of strides within it lands on an amount: wrapping arithmetic finds it exactly.
        let distance = UInt64(bitPattern: ascending ? end.minorUnits &- first : first &- end.minorUnits)
        let travel = (distance / step.magnitude) &* step.magnitude
        let hasAmounts = ascending ? first <= end.minorUnits : first >= end.minorUnits

        self.upcoming = hasAmounts ? first : nil
        self.last = ascending ? first &+ Int64(bitPattern: travel) : first &- Int64(bitPattern: travel)
        self.start = first
        self.end = end.minorUnits
        self.stride = step
        self.storage = start.storage
    }

    @inlinable
    mutating func next() -> MoneyOf<C>? {
        guard let current = upcoming else {
            return nil
        }

        upcoming = current == last ? nil : current &+ stride

        return MoneyOf(unchecked: current, storage: storage)
    }

    // The exact count, as the standard library's stride sequences report, so `Array(_:)` allocates once.
    // `last` is known, so a division counts the amounts left without stepping through them. From
    // `upcoming` to `last` is below 2⁶⁴, so `UInt64` holds it; a count beyond `Int` is reported as
    // `Int.max`, still an underestimate.
    @inlinable
    var underestimatedCount: Int {
        guard let current = upcoming else {
            return 0
        }

        let travel = UInt64(bitPattern: stride > 0 ? last &- current : current &- last)
        let (count, overflow) = (travel / stride.magnitude).addingReportingOverflow(1)

        return overflow ? .max : Int(exactly: count) ?? .max
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
