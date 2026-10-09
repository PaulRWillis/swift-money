public extension MoneyOf {
    /// The amounts from a start up to, but not including, an end, one stride apart.
    ///
    /// What ``stride(from:to:by:)`` returns for amounts, as the standard library's `StrideTo` is
    /// for numbers. It steps by an amount rather than an `Int`, so a stride above `Int32.max`
    /// doesn't trap where `Int` is 32 bits.
    ///
    /// ```swift
    /// let end = GBP(minorUnits: 3_00)
    /// let amounts = stride(from: .zero, to: end, by: .majorUnit)   // GBP.StrideTo
    /// Array(amounts)  // £0, £1, £2
    /// ```
    struct StrideTo: Sequence, Sendable {
        /// The amounts of the sequence, or `nil` when no amount lies before the end.
        @usableFromInline
        let progression: StrideProgression?

        /// Creates the amounts from a start up to, but not including, an end, one stride apart.
        ///
        /// Every amount takes `start`'s currency; the currencies of `end` and `stride` aren't
        /// checked.
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
            self.progression = MoneyOf.StrideProgression(from: start, to: end, by: stride)
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
