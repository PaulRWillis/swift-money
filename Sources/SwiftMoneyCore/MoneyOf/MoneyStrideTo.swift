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
    // `nil` once `last` has been returned, or from the start when no amount lies before the end.
    @usableFromInline
    var upcoming: MoneyOf<C>?

    // The final amount returned. Every amount from `start` to here is before the end, so each step
    // fits `Int64` and needs no range check.
    @usableFromInline
    let last: MoneyOf<C>

    @usableFromInline
    let start: MoneyOf<C>

    @usableFromInline
    let end: MoneyOf<C>

    @usableFromInline
    let stride: MoneyOf<C>.Stride

    @inlinable
    init(
        from start: MoneyOf<C>,
        to end: MoneyOf<C>,
        by stride: MoneyOf<C>.Stride
    ) {
        let first = start.minorUnits
        let step = stride.amount.minorUnits
        let ascending = step > 0

        // Before the end, the distance to it is at least one and below 2⁶⁴, so `UInt64` holds it, and a
        // whole number of strides short of it lands on an amount: wrapping arithmetic finds it exactly.
        let distance = UInt64(bitPattern: ascending ? end.minorUnits &- first : first &- end.minorUnits)
        let travel = ((distance &- 1) / step.magnitude) &* step.magnitude
        let hasAmounts = ascending ? first < end.minorUnits : first > end.minorUnits
        let last = ascending ? first &+ Int64(bitPattern: travel) : first &- Int64(bitPattern: travel)

        self.upcoming = hasAmounts ? start : nil
        self.last = MoneyOf(unchecked: last, storage: start.storage)
        self.start = start
        self.end = end
        self.stride = stride
    }

    @inlinable
    mutating func next() -> MoneyOf<C>? {
        guard let current = upcoming else {
            return nil
        }

        upcoming = current.minorUnits == last.minorUnits
            ? nil
            : MoneyOf(unchecked: current.minorUnits &+ stride.amount.minorUnits, storage: current.storage)

        return current
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

        let step = stride.amount.minorUnits
        let travel = UInt64(
            bitPattern: step > 0 ? last.minorUnits &- current.minorUnits : current.minorUnits &- last.minorUnits
        )
        let (count, overflow) = (travel / step.magnitude).addingReportingOverflow(1)

        return overflow ? .max : Int(exactly: count) ?? .max
    }

    // Rules out an amount outside the span at once, as the standard library does; `nil` makes
    // `contains(_:)` step through the rest.
    @inlinable
    func _customContainsEquatableElement(_ element: MoneyOf<C>) -> Bool? {
        let minorUnits = element.minorUnits
        let outside = stride.amount.minorUnits < 0
            ? minorUnits <= end.minorUnits || start.minorUnits < minorUnits
            : minorUnits < start.minorUnits || end.minorUnits <= minorUnits

        return outside ? false : nil
    }
}
