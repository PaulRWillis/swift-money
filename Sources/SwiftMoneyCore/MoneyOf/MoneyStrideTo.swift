/// The amounts from a start up to, but not including, an end, one stride apart.
///
/// What ``stride(from:to:by:)`` returns for amounts, as the standard library's `StrideTo` is for
/// numbers. It steps by an amount rather than an `Int`, so a stride above `Int32.max` doesn't trap
/// where `Int` is 32 bits.
///
/// ```swift
/// let end = GBP(minorUnits: 3_00)
/// let amounts: MoneyStrideTo<Currencies.GBP> =stride(from: .zero, to: end, by: .majorUnit)
/// Array(amounts)  // £0, £1, £2
/// ```
public struct MoneyStrideTo<C: CurrencyRepresentation>: Sequence, Sendable {
    /// The currency of every amount in the sequence.
    @usableFromInline
    let currency: C.Storage

    /// The positions of the amounts, or `nil` when no amount lies before the end.
    @usableFromInline
    let positions: StridePositions?

    /// Creates the amounts from a start up to, but not including, an end, one stride apart.
    ///
    /// Every amount takes `start`'s currency; the currencies of `end` and `stride` aren't checked.
    ///
    /// - Parameters:
    ///   - start: The first amount, unless it is already at or past `end`.
    ///   - end: The amount the sequence stops before.
    ///   - stride: The amount each step moves by.
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

    /// Returns an iterator over the amounts.
    ///
    /// - Returns: An iterator that starts at the first amount.
    @inlinable
    public func makeIterator() -> MoneyStrideToIterator<C> {
        MoneyStrideToIterator(currency: currency, remaining: positions)
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
