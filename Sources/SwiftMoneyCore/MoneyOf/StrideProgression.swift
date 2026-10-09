extension MoneyOf {
    /// The amounts of a stride sequence from ``first`` on: a finite arithmetic progression that is
    /// never empty.
    ///
    /// Holds the first amount, how many steps follow it, and the stride's minor units. Equality
    /// compares the three, so one-amount progressions with different strides are unequal.
    @usableFromInline
    struct StrideProgression: Sendable, Equatable, Hashable {
        /// The first amount, whose currency every amount takes.
        @usableFromInline
        let first: MoneyOf

        /// How many steps follow the first amount, each landing on an amount.
        @usableFromInline
        let stepsAfterFirst: DistanceAhead.StepCount

        /// The minor units each step moves by. Negative moves downward.
        @usableFromInline
        let strideMinorUnits: NonZero<MinorUnits>

        /// Creates the amounts from a start up to, but not including, an end, one stride apart.
        ///
        /// Doesn't look at the currencies of `end` and `stride`.
        ///
        /// - Parameters:
        ///   - start: The first amount.
        ///   - end: The amount the progression stops before.
        ///   - stride: The amount each step moves by.
        /// - Returns: `nil` if `start` is at or past `end` in the stride's direction.
        @inlinable
        init?(
            from start: MoneyOf,
            to end: MoneyOf,
            by stride: Stride
        ) {
            let strideMinorUnits = stride.minorUnits
            guard let distance = DistanceAhead(from: start, to: end, along: strideMinorUnits)?
                .shortenedByOneMinorUnit else {
                return nil
            }

            self.init(
                unchecked: start,
                stepsAfterFirst: distance.wholeSteps,
                strideMinorUnits: strideMinorUnits
            )
        }

        /// Creates the amounts from a start up to an end, one stride apart, including the end only
        /// if a step lands on it.
        ///
        /// Doesn't look at the currencies of `end` and `stride`.
        ///
        /// - Parameters:
        ///   - start: The first amount.
        ///   - end: The last amount, if a step lands on it.
        ///   - stride: The amount each step moves by.
        /// - Returns: `nil` if `start` is past `end` in the stride's direction.
        @inlinable
        init?(
            from start: MoneyOf,
            through end: MoneyOf,
            by stride: Stride
        ) {
            let strideMinorUnits = stride.minorUnits
            guard let distance = DistanceAhead(from: start, to: end, along: strideMinorUnits) else {
                return nil
            }

            self.init(
                unchecked: start,
                stepsAfterFirst: distance.wholeSteps,
                strideMinorUnits: strideMinorUnits
            )
        }

        /// Creates a progression without checking that its last amount is in range.
        ///
        /// For ``init(from:to:by:)``, ``init(from:through:by:)`` and ``advanced``, which find
        /// `stepsAfterFirst` so that every step lands on an amount.
        ///
        /// - Parameters:
        ///   - first: The first amount.
        ///   - stepsAfterFirst: How many steps follow `first`, each landing on an amount.
        ///   - strideMinorUnits: The minor units each step moves by.
        @inlinable
        init(
            unchecked first: MoneyOf,
            stepsAfterFirst: DistanceAhead.StepCount,
            strideMinorUnits: NonZero<MinorUnits>
        ) {
            self.first = first
            self.stepsAfterFirst = stepsAfterFirst
            self.strideMinorUnits = strideMinorUnits
        }

        /// The progression after one step, or `nil` when no step follows the first amount.
        @inlinable
        var advanced: Self? {
            guard let remaining = stepsAfterFirst.decremented else {
                return nil
            }

            // A step follows `first`, so moving by one lands on an amount and can't wrap.
            let nextMinorUnits = first.minorUnits &+ strideMinorUnits.rawValue

            return Self(
                unchecked: MoneyOf(unchecked: nextMinorUnits, storage: first.storage),
                stepsAfterFirst: remaining,
                strideMinorUnits: strideMinorUnits
            )
        }

        /// Returns whether an amount is in the progression, without stepping through it.
        ///
        /// - Parameter amount: The amount to look for.
        /// - Returns: `true` if `amount` is in the first amount's currency, no more than
        ///   `stepsAfterFirst` steps ahead of it, and a whole number of steps from it; otherwise,
        ///   `false`.
        @inlinable
        func contains(_ amount: MoneyOf) -> Bool {
            guard amount.storage == first.storage,
                  let distance = DistanceAhead(from: first, to: amount, along: strideMinorUnits),
                  distance.isWithin(stepsAfterFirst) else {
                return false
            }

            return distance.isWholeSteps
        }

        /// The number of amounts, or `Int.max` if that many don't fit `Int`.
        @inlinable
        var underestimatedCount: Int {
            let (count, overflow) = stepsAfterFirst.count.addingReportingOverflow(1)

            guard !overflow, let exact = Int(exactly: count) else {
                return .max
            }

            return exact
        }
    }
}
