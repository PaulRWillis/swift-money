/// The amounts from a start up to an end, one stride apart, including the end only if a step lands
/// on it.
///
/// What ``stride(from:through:by:)`` returns for amounts, as the standard library's `StrideThrough`
/// is for numbers. It steps by an amount rather than an `Int`, so a stride above `Int32.max`
/// doesn't trap where `Int` is 32 bits.
///
/// ```swift
/// let end = GBP(minorUnits: 2_50)
/// let amounts: MoneyStrideThrough<Currencies.GBP>
/// amounts = stride(from: .zero, through: end, by: .majorUnit)
/// Array(amounts)  // £0, £1, £2: no £2.50, since no step lands on it
/// ```
public struct MoneyStrideThrough<C: CurrencyRepresentation>: Sequence, Sendable {
    /// The currency of every amount in the sequence.
    @usableFromInline
    let currency: C.Storage

    /// The positions of the amounts, or `nil` when the start is past the end.
    @usableFromInline
    let positions: StridePositions?

    /// Creates the amounts from a start up to an end, one stride apart, including the end only if a
    /// step lands on it.
    ///
    /// Every amount takes `start`'s currency; the currencies of `end` and `stride` aren't checked.
    ///
    /// - Parameters:
    ///   - start: The first amount, unless it is already past `end`.
    ///   - end: The last amount, if a step lands on it.
    ///   - stride: The amount each step moves by.
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

    /// Returns an iterator over the amounts.
    ///
    /// - Returns: An iterator that starts at the first amount.
    @inlinable
    public func makeIterator() -> MoneyStrideThroughIterator<C> {
        MoneyStrideThroughIterator(currency: currency, remaining: positions)
    }

    /// The number of amounts in the sequence, or `Int.max` if that many don't fit `Int`.
    ///
    /// The count is exact, as the standard library's stride sequences report it.
    @inlinable
    public var underestimatedCount: Int {
        guard let positions else {
            return 0
        }

        return positions.count
    }

    /// Returns whether the sequence holds an amount, without stepping through it.
    ///
    /// - Parameter element: The amount to look for.
    /// - Returns: `true` if `element` is in the sequence's currency, lies from its first amount to
    ///   its last, and is a whole number of strides from the first; otherwise, `false`. Never
    ///   `nil`.
    @inlinable
    public func _customContainsEquatableElement(_ element: MoneyOf<C>) -> Bool? {
        guard let positions else {
            return false
        }

        return element.storage == currency && positions.contains(element.minorUnits)
    }
}
