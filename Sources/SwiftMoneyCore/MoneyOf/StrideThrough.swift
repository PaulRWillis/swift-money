public extension MoneyOf {
    /// The amounts from a start up to an end, one stride apart, including the end only if a step
    /// lands on it.
    ///
    /// What ``stride(from:through:by:)`` returns for amounts, as the standard library's
    /// `StrideThrough` is for numbers. It steps by an amount rather than an `Int`, so a stride
    /// above `Int32.max` doesn't trap where `Int` is 32 bits.
    ///
    /// ```swift
    /// let end = GBP(minorUnits: 2_50)
    /// // GBP.StrideThrough
    /// let amounts = stride(from: .zero, through: end, by: .majorUnit)
    /// Array(amounts)  // £0, £1, £2: no £2.50, since no step lands on it
    /// ```
    struct StrideThrough: Sequence, Sendable {
        /// The amounts of the sequence, or `nil` when the start is past the end.
        @usableFromInline
        let progression: StrideProgression?

        /// Creates the amounts from a start up to an end, one stride apart, including the end only
        /// if a step lands on it.
        ///
        /// Every amount takes `start`'s currency; the currencies of `end` and `stride` aren't
        /// checked.
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
            self.progression = MoneyOf.StrideProgression(from: start, through: end, by: stride)
        }

        /// Returns an iterator over the amounts.
        ///
        /// - Returns: An iterator that starts at the first amount.
        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(remaining: progression)
        }

        /// The number of amounts in the sequence, or `Int.max` if that many don't fit `Int`.
        ///
        /// Exact, as the standard library's stride sequences report it, unless it exceeds
        /// `Int.max`.
        @inlinable
        public var underestimatedCount: Int {
            progression?.underestimatedCount ?? 0
        }

        /// Returns whether the sequence holds an amount, without stepping through it.
        ///
        /// - Parameter element: The amount to look for.
        /// - Returns: `true` if `element` is in the sequence's currency, lies from its first amount
        ///   to its last, and is a whole number of steps from the first; otherwise, `false`. Never
        ///   `nil`.
        @inlinable
        public func _customContainsEquatableElement(_ element: MoneyOf<C>) -> Bool? {
            progression?.contains(element) ?? false
        }
    }
}
