extension MoneyOf {
    /// How far an amount is ahead of another, measured along a stride. Never negative.
    ///
    /// Up to 2⁶⁴ − 1 minor units, which no amount can hold. Not `Comparable`: two distances along
    /// different strides have no order. Compare a distance with a number of steps along its own
    /// stride, with ``isWithin(_:)``.
    @usableFromInline
    struct DistanceAhead: Sendable, Equatable, Hashable {
        /// The width a distance and a number of steps are counted in.
        @usableFromInline
        typealias Magnitude = MinorUnits.Magnitude

        /// The distance in minor units.
        @usableFromInline
        let minorUnits: Magnitude

        /// The minor units of the stride the distance is measured along. Negative moves downward.
        @usableFromInline
        let strideMinorUnits: NonZeroInt64

        /// Creates the distance from one amount to another, returning `nil` if the second is behind
        /// the first.
        ///
        /// Doesn't look at currency; callers have checked it.
        ///
        /// - Parameters:
        ///   - start: The amount the distance is measured from.
        ///   - target: The amount the distance is measured to.
        ///   - strideMinorUnits: The minor units of the stride, whose sign says which way is ahead.
        /// - Returns: `nil` if `target` is behind `start` in the stride's direction.
        @inlinable
        init?(
            from start: MoneyOf,
            to target: MoneyOf,
            along strideMinorUnits: NonZeroInt64
        ) {
            let start = start.minorUnits
            let target = target.minorUnits
            let difference: MinorUnits
            switch StrideDirection(of: strideMinorUnits) {
            case .upward:
                guard start <= target else {
                    return nil
                }

                difference = target &- start
            case .downward:
                guard target <= start else {
                    return nil
                }

                difference = start &- target
            }

            // Ahead of the start, the difference is below 2⁶⁴, so its wrapped bit pattern is exact.
            self.init(
                minorUnits: Magnitude(bitPattern: difference),
                strideMinorUnits: strideMinorUnits
            )
        }

        /// Creates a distance from its minor units. Any value is a valid distance.
        ///
        /// - Parameters:
        ///   - minorUnits: The distance in minor units.
        ///   - strideMinorUnits: The minor units of the stride the distance is measured along.
        @inlinable
        init(
            minorUnits: Magnitude,
            strideMinorUnits: NonZeroInt64
        ) {
            self.minorUnits = minorUnits
            self.strideMinorUnits = strideMinorUnits
        }

        /// The distance one minor unit shorter, or `nil` when the distance is zero.
        @inlinable
        var shortenedByOneMinorUnit: Self? {
            guard minorUnits > 0 else {
                return nil
            }

            return Self(minorUnits: minorUnits &- 1, strideMinorUnits: strideMinorUnits)
        }

        /// The stride's size in minor units, whichever way it moves.
        @inlinable
        var strideSize: Magnitude {
            strideMinorUnits.rawValue.magnitude
        }

        /// The number of whole steps in the distance, rounded down.
        @inlinable
        var wholeSteps: StepCount {
            StepCount(count: minorUnits / strideSize)
        }

        /// Whether the distance is a whole number of steps.
        @inlinable
        var isWholeSteps: Bool {
            minorUnits % strideSize == 0
        }

        /// Returns whether the distance is no more than a number of steps along its own stride.
        ///
        /// True when `steps` times ``strideSize`` overflows ``Magnitude``, since no distance is
        /// that long.
        ///
        /// - Parameter steps: The number of steps to compare with.
        /// - Returns: `true` if the distance is at most `steps` steps; otherwise, `false`.
        @inlinable
        func isWithin(_ steps: StepCount) -> Bool {
            let (span, overflow) = steps.count.multipliedReportingOverflow(by: strideSize)

            return overflow || minorUnits <= span
        }

        /// A number of steps, each one move by the stride.
        @usableFromInline
        struct StepCount: Sendable, Equatable, Hashable {
            /// The number of steps.
            @usableFromInline
            let count: Magnitude

            /// Creates a number of steps. Any value is a valid count.
            ///
            /// - Parameter count: The number of steps.
            @inlinable
            init(count: Magnitude) {
                self.count = count
            }

            /// One step fewer, or `nil` when the count is zero.
            @inlinable
            var decremented: Self? {
                guard count > 0 else {
                    return nil
                }

                return Self(count: count &- 1)
            }
        }
    }
}
