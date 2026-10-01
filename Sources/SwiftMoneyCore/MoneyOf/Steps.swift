public extension MoneyOf {
    /// Every amount between two bounds, one stride apart, always ending exactly on the far bound.
    ///
    /// The stops of a slider or a stepper. Where `stride(from:through:by:)` leaves out an end no step
    /// lands on, steps always hold both bounds, so the largest amount allowed can always be chosen:
    ///
    /// ```swift
    /// let steps = try (minimum...maximum).steps(by: .majorUnits(100))
    /// // £10, £110, £210, £250 when the range is £10...£250
    /// ```
    ///
    /// A positive stride runs from the lower bound up to the upper; a negative one starts on the upper
    /// bound and counts down to the lower. Steps are never empty: bounds that are equal give one step.
    ///
    /// `count` and the subscript take constant time however many steps there are, as for any
    /// random-access collection. So do `firstIndex(of:)`, `lastIndex(of:)` and `contains(_:)`, which
    /// work out an amount's position from the bounds and the stride rather than stepping through.
    /// So do `index(approximating:tiesTo:)` and `index(approximating:rounding:)`, which round an
    /// amount between two steps to one of them.
    ///
    /// Two sets of steps are equal when they hold the same amounts, in the same order and the same
    /// currency. A stride longer than the span gives the same steps as a stride of the span itself, so
    /// the two are equal and report the same ``stride``. A single step has no direction, so its
    /// ``stride`` is one minor unit upward, whatever stride built it.
    struct Steps: RandomAccessCollection, Equatable, Hashable, Sendable {
        /// An amount in the steps.
        public typealias Element = MoneyOf<C>

        /// The positions of every step, in order.
        public typealias Indices = DefaultIndices<Self>

        /// The currency of every step, stored as an amount stores it.
        @usableFromInline
        let storage: C.Storage

        /// The minor units of the lowest step and the highest.
        @usableFromInline
        let span: ClosedRange<MoneyOf<C>.MinorUnits>

        /// The minor units between neighboring steps, no more than the span's width; one upward when
        /// the width is zero. Its sign is the direction.
        @usableFromInline
        let step: NonZeroInt64

        // Stored rather than worked out from `span` and `step`, since `endIndex` reads it on every
        // step of a loop.
        /// The number of steps, at least one.
        public let count: Int

        /// Creates steps without checking that the parts agree.
        ///
        /// - Parameters:
        ///   - storage: The currency of every step, stored as an amount stores it.
        ///   - span: The minor units of the lowest step and the highest.
        ///   - step: The minor units between neighboring steps, no more than the span's width, or one
        ///     upward when the width is zero.
        ///   - count: The number of steps that `span` and `step` give.
        @usableFromInline
        init(
            unchecked storage: C.Storage,
            span: ClosedRange<MoneyOf<C>.MinorUnits>,
            step: NonZeroInt64,
            count: Int
        ) {
            self.storage = storage
            self.span = span
            self.step = step
            self.count = count
        }

        /// The gap between neighboring steps, never longer than the span. Its sign is the direction.
        ///
        /// A negative stride means the steps run from the upper bound down to the lower. The last gap,
        /// onto the far bound, may be shorter. A single step has no neighbor, so its stride is one
        /// minor unit upward.
        @inlinable
        public var stride: MoneyOf<C>.Stride {
            MoneyOf.Stride(unchecked: MoneyOf(unchecked: step.rawValue, storage: storage))
        }

        /// The position of the first step.
        @inlinable
        public var startIndex: Index {
            Index(offset: 0)
        }

        /// The position one past the last step.
        @inlinable
        public var endIndex: Index {
            Index(offset: count)
        }

        /// Accesses the step at a position.
        ///
        /// - Parameter position: A position from `startIndex` up to, but not including, `endIndex`.
        /// - Precondition: `position` is a position in the steps, as for `Array`'s subscript. Use
        ///   `index(_:offsetBy:limitedBy:)` to move without leaving them.
        @inlinable
        public subscript(position: Index) -> MoneyOf<C> {
            guard position.offset >= 0, position.offset < count else {
                preconditionFailure("Index out of range")  // coverage:ignore — exit-test trap
            }

            return amount(at: position.offset)
        }

        /// Returns the position after a position.
        @inlinable
        public func index(after i: Index) -> Index {
            Index(offset: i.offset + 1)
        }

        /// Returns the position before a position.
        @inlinable
        public func index(before i: Index) -> Index {
            Index(offset: i.offset - 1)
        }

        /// Returns the position a distance from a position.
        ///
        /// - Complexity: O(1).
        @inlinable
        public func index(
            _ i: Index,
            offsetBy distance: Int
        ) -> Index {
            Index(offset: i.offset + distance)
        }

        /// Returns the position a distance from a position, unless that passes a limit.
        ///
        /// - Returns: `nil` if moving `distance` from `i` goes beyond `limit`, in the direction moved.
        /// - Complexity: O(1).
        @inlinable
        public func index(
            _ i: Index,
            offsetBy distance: Int,
            limitedBy limit: Index
        ) -> Index? {
            let room = limit.offset - i.offset
            let passesLimit = distance > 0 ? room >= 0 && room < distance : room <= 0 && distance < room

            return passesLimit ? nil : Index(offset: i.offset + distance)
        }

        /// Returns the number of steps from one position to another, negative if `end` is before `start`.
        ///
        /// - Complexity: O(1).
        @inlinable
        public func distance(
            from start: Index,
            to end: Index
        ) -> Int {
            end.offset - start.offset
        }

        /// Returns the position of an amount among the steps, without stepping through them.
        ///
        /// Backs `firstIndex(of:)`. The result is `.some(nil)` when the amount is not a step.
        ///
        /// - Complexity: O(1).
        @inlinable
        public func _customIndexOfEquatableElement(_ element: MoneyOf<C>) -> Index?? {
            .some(offset(of: element).map(Index.init(offset:)))
        }

        /// Returns the position of an amount among the steps, without stepping through them.
        ///
        /// Backs `lastIndex(of:)`. Steps never repeat, so the last match is the only one.
        ///
        /// - Complexity: O(1).
        @inlinable
        public func _customLastIndexOfEquatableElement(_ element: MoneyOf<C>) -> Index?? {
            _customIndexOfEquatableElement(element)
        }

        /// Returns whether an amount is one of the steps, without stepping through them.
        ///
        /// Backs `contains(_:)`.
        ///
        /// - Complexity: O(1).
        @inlinable
        public func _customContainsEquatableElement(_ element: MoneyOf<C>) -> Bool? {
            offset(of: element) != nil
        }
    }
}

extension MoneyOf.Steps {
    /// Creates steps over a span in one currency, counting them and settling the step.
    ///
    /// A step longer than the span is shortened to it, and a span of one amount gets a step of one
    /// minor unit upward, so equal steps compare and hash equal.
    ///
    /// - Parameters:
    ///   - storage: The currency of every step, stored as an amount stores it.
    ///   - span: The minor units of the lowest step and the highest.
    ///   - requested: The minor units between neighboring steps. Negative counts down.
    /// - Throws: ``MoneyStepsParsingError/tooManySteps`` if there would be more steps than `Int` can
    ///   count.
    @inlinable
    init(
        storage: C.Storage,
        span: ClosedRange<MoneyOf<C>.MinorUnits>,
        by requested: NonZeroInt64
    ) throws(MoneyStepsParsingError<C>) {
        // The width reaches 2⁶⁴ − 1 minor units, which `Int64` cannot hold but `UInt64` can, and an
        // `Int128` divide is a library call.
        let width = UInt64(bitPattern: span.upperBound &- span.lowerBound)

        guard width > 0 else {
            self.init(unchecked: storage, span: span, step: NonZeroInt64(unchecked: 1), count: 1)
            return
        }

        let magnitude = requested.rawValue.magnitude
        let (steps, overflow) = ((width &- 1) / magnitude).addingReportingOverflow(2)
        guard !overflow, let count = Int(exactly: steps) else {
            throw .tooManySteps
        }

        // The shortened step is at most the requested one and at least one, so its bit pattern,
        // negated for a downward step, fits `Int64` and is not zero.
        let shortened = Swift.min(magnitude, width)
        let settled: Int64
        switch StrideDirection(of: requested) {
        case .upward:
            settled = Int64(bitPattern: shortened)
        case .downward:
            settled = Int64(bitPattern: 0 &- shortened)
        }

        self.init(unchecked: storage, span: span, step: NonZeroInt64(unchecked: settled), count: count)
    }

    /// The way the steps run.
    @inlinable
    var direction: StrideDirection {
        StrideDirection(of: step)
    }

    /// The minor units of the bound the steps start on.
    @inlinable
    var nearBound: MoneyOf<C>.MinorUnits {
        switch direction {
        case .upward:
            span.lowerBound
        case .downward:
            span.upperBound
        }
    }

    /// The minor units of the bound the steps always end on.
    @inlinable
    var farBound: MoneyOf<C>.MinorUnits {
        switch direction {
        case .upward:
            span.upperBound
        case .downward:
            span.lowerBound
        }
    }

    /// Returns the amount a number of steps from the first.
    ///
    /// - Parameter offset: How many steps the amount is from the first, from zero up to `count - 1`.
    /// - Returns: The far bound for the last offset; otherwise the near bound moved `offset` steps.
    @inlinable
    func amount(at offset: Int) -> MoneyOf<C> {
        guard offset != count &- 1 else {
            return MoneyOf(unchecked: farBound, storage: storage)
        }

        // An offset before the last lands from the near bound up to, but not including, the far one,
        // so it fits `Int64` even when the product does not: wrapping modulo 2⁶⁴ lands on it exactly.
        let minorUnits = nearBound &+ Int64(truncatingIfNeeded: offset) &* step.rawValue

        return MoneyOf(unchecked: minorUnits, storage: storage)
    }

    /// Returns how many steps from the first the step equal to an amount is.
    ///
    /// - Parameter element: The amount to find.
    /// - Returns: The offset of the step equal to `element`, or `nil` if `element` is in another
    ///   currency or isn't a step.
    @inlinable
    func offset(of element: MoneyOf<C>) -> Int? {
        let minorUnits = element.minorUnits
        guard element.storage == storage, span.contains(minorUnits) else {
            return nil
        }
        guard minorUnits != farBound else {
            return count &- 1
        }

        // Short of the far bound, a whole number of strides from the near one is a step before the
        // last, which `Int` counts.
        let (steps, remainder) = distanceFromNearBound(to: minorUnits)
            .quotientAndRemainder(dividingBy: step.rawValue.magnitude)

        return remainder == 0 ? Int(truncatingIfNeeded: steps) : nil
    }

    /// Returns whether a step's position, counted from the lower bound, is even or odd.
    ///
    /// - Parameter offset: How many steps the step is from the first, from zero up to `count - 1`.
    /// - Returns: The parity of `offset` for steps that run upward; otherwise the parity of the
    ///   step's distance from the last step.
    @inlinable
    func parityFromLowerBound(ofOffset offset: Int) -> Parity {
        switch direction {
        case .upward:
            Parity(of: offset)
        case .downward:
            // `offset` is from zero up to `count - 1`, so the difference is too.
            Parity(of: count &- 1 &- offset)
        }
    }

    /// Returns how far an amount is from the near bound, toward the far one.
    ///
    /// - Parameter minorUnits: The amount's minor units, from the lowest step to the highest.
    /// - Returns: The distance in minor units, which is at most the span's width.
    @inlinable
    func distanceFromNearBound(to minorUnits: MoneyOf<C>.MinorUnits) -> UInt64 {
        // A distance reaches 2⁶⁴ − 1 across the widest span, which `Int64` cannot hold, but
        // wrapping gives its bit pattern.
        switch direction {
        case .upward:
            UInt64(bitPattern: minorUnits &- span.lowerBound)
        case .downward:
            UInt64(bitPattern: span.upperBound &- minorUnits)
        }
    }

    /// Which side of an amount a step is on.
    @usableFromInline
    enum Side {
        /// At or below the amount.
        case below

        /// At or above the amount.
        case above

        /// Creates the side of an amount that is farther from zero.
        ///
        /// - Parameter sign: The amount's sign, with zero counting as positive.
        @inlinable
        init(awayFromZeroFor sign: Sign) {
            switch sign {
            case .positive:
                self = .above
            case .negative:
                self = .below
            }
        }

        /// The other side of the amount.
        @inlinable
        var opposite: Self {
            switch self {
            case .below:
                .above
            case .above:
                .below
            }
        }
    }

    /// A step beside an amount, and how far the amount is from it.
    @usableFromInline
    struct Neighbor {
        /// How many steps from the first the step is.
        @usableFromInline
        let offset: Int

        /// The minor units from the amount to the step.
        @usableFromInline
        let distance: UInt64

        /// Creates a step beside an amount.
        ///
        /// - Parameters:
        ///   - offset: How many steps from the first the step is.
        ///   - distance: The minor units from the amount to the step.
        @inlinable
        init(offset: Int, distance: UInt64) {
            self.offset = offset
            self.distance = distance
        }
    }

    /// The steps either side of an amount.
    @usableFromInline
    struct Neighbors {
        /// The highest step at or below the amount.
        @usableFromInline
        let below: Neighbor

        /// The lowest step at or above the amount.
        @usableFromInline
        let above: Neighbor

        /// Creates the steps either side of an amount.
        ///
        /// - Parameters:
        ///   - below: The highest step at or below the amount.
        ///   - above: The lowest step at or above the amount.
        @inlinable
        init(below: Neighbor, above: Neighbor) {
            self.below = below
            self.above = above
        }

        /// Creates the steps either side of an amount on a step: that step on both sides, at no
        /// distance.
        ///
        /// - Parameter offset: How many steps from the first the amount's step is.
        @inlinable
        init(onStepAt offset: Int) {
            let onStep = Neighbor(offset: offset, distance: 0)
            self.init(below: onStep, above: onStep)
        }

        /// Accesses the step on one side of the amount.
        ///
        /// - Parameter side: The side of the amount to take the step from.
        /// - Returns: The step on `side`.
        @inlinable
        subscript(side: Side) -> Neighbor {
            switch side {
            case .below:
                below
            case .above:
                above
            }
        }
    }

    /// Returns the steps either side of an amount, and how far the amount is from each.
    ///
    /// An amount on a step has that step on both sides, at no distance from either. Otherwise the
    /// two are neighbors, and the distances add up to the gap between them.
    ///
    /// - Parameter minorUnits: The amount's minor units, from the lowest step to the highest.
    /// - Returns: The highest step at or below the amount and the lowest at or above.
    /// - Complexity: O(1).
    @inlinable
    func neighbors(of minorUnits: MoneyOf<C>.MinorUnits) -> Neighbors {
        guard minorUnits != farBound else {
            return Neighbors(onStepAt: count &- 1)
        }

        let gap = step.rawValue.magnitude
        let (behind, remainder) = distanceFromNearBound(to: minorUnits)
            .quotientAndRemainder(dividingBy: gap)
        // Short of the far bound, fewer than `count - 1` whole gaps lie behind the amount, so `Int`
        // holds their number.
        let offset = Int(truncatingIfNeeded: behind)
        guard remainder != 0 else {
            return Neighbors(onStepAt: offset)
        }

        // The step ahead is a whole gap on, unless it is the far bound, which may be nearer.
        let width = distanceFromNearBound(to: farBound)
        let gapAhead = Swift.min(gap, width - behind * gap)
        let behindStep = Neighbor(offset: offset, distance: remainder)
        let aheadStep = Neighbor(offset: offset + 1, distance: gapAhead - remainder)
        switch direction {
        case .upward:
            return Neighbors(below: behindStep, above: aheadStep)
        case .downward:
            return Neighbors(below: aheadStep, above: behindStep)
        }
    }

    /// Returns how many steps from the first the step nearest an amount is, clamping an amount
    /// beyond the steps onto the nearer end.
    ///
    /// - Parameters:
    ///   - minorUnits: The amount's minor units, in the steps' currency.
    ///   - tie: How to choose between two steps the same distance away.
    /// - Returns: The offset of the nearest step, the nearer end for an amount beyond the steps.
    /// - Complexity: O(1).
    @inlinable
    func offset(
        approximating minorUnits: MoneyOf<C>.MinorUnits,
        tiesTo tie: TieBreakingRule
    ) -> Int {
        let inside = Swift.min(Swift.max(minorUnits, span.lowerBound), span.upperBound)
        let beside = neighbors(of: inside)
        guard beside.below.distance == beside.above.distance else {
            let nearer: Side = beside.below.distance < beside.above.distance ? .below : .above
            return beside[nearer].offset
        }

        switch tie {
        case .even:
            let belowParity = parityFromLowerBound(ofOffset: beside.below.offset)
            return beside[belowParity == .even ? .below : .above].offset
        case .awayFromZero:
            return beside[Side(awayFromZeroFor: Sign(of: minorUnits))].offset
        }
    }

    /// Returns how many steps from the first the step an amount rounds to is, if a step satisfies
    /// the rule.
    ///
    /// - Parameters:
    ///   - minorUnits: The amount's minor units, in the steps' currency.
    ///   - rule: Which side of the amount to take the step from.
    /// - Returns: The offset of the step `rule` picks.
    /// - Throws: ``MoneyStepsRoundingError/outOfBounds`` if the amount is beyond the steps and
    ///   `rule` rules out the only step beside it.
    /// - Complexity: O(1).
    @inlinable
    func offset(
        approximating minorUnits: MoneyOf<C>.MinorUnits,
        rounding rule: DirectedRoundingRule
    ) throws(MoneyStepsRoundingError<C>) -> Int {
        // Beyond the steps there is one neighbor and no second size to compare, so `.towardZero`
        // and `.awayFromZero` look below or above by the amount's sign.
        let away = Side(awayFromZeroFor: Sign(of: minorUnits))
        let side: Side = switch rule {
        case .down:
            .below
        case .up:
            .above
        case .towardZero:
            away.opposite
        case .awayFromZero:
            away
        }
        switch side {
        case .below:
            guard minorUnits >= span.lowerBound else {
                throw .outOfBounds
            }
        case .above:
            guard minorUnits <= span.upperBound else {
                throw .outOfBounds
            }
        }

        // Only the end on `side` is checked; an amount past the other end has that end as its step.
        let inside = Swift.min(Swift.max(minorUnits, span.lowerBound), span.upperBound)
        let beside = neighbors(of: inside)

        // Both neighbors are steps, so they fit `Int64` and wrapping lands on them exactly, even
        // where a distance is too large for `Int64`.
        let belowSize = (inside &- Int64(bitPattern: beside.below.distance)).magnitude
        let aboveSize = (inside &+ Int64(bitPattern: beside.above.distance)).magnitude
        switch rule {
        case .down, .up:
            return beside[side].offset
        case .towardZero where belowSize != aboveSize:
            return beside[belowSize < aboveSize ? .below : .above].offset
        case .awayFromZero where belowSize != aboveSize:
            return beside[belowSize > aboveSize ? .below : .above].offset
        // Neighbors of equal size, such as −£10 and £10, give the one with the amount's sign.
        case .towardZero, .awayFromZero:
            return beside[away].offset
        }
    }

    /// Creates steps from bounds and a step already known to share a currency, so the typed and
    /// runtime parses report the same failures in the same order.
    ///
    /// - Parameters:
    ///   - bounds: The lowest step and the highest, the intended lower one first.
    ///   - stride: The gap between neighboring steps. Negative counts down.
    /// - Throws: ``MoneyStepsParsingError/invertedBounds(lowerBound:upperBound:)`` if the lower
    ///   bound is above the upper; otherwise ``MoneyStepsParsingError/zeroStride`` if `stride` is
    ///   zero; otherwise ``MoneyStepsParsingError/tooManySteps`` if there would be more steps than
    ///   `Int` can count.
    @inlinable
    init(
        parsing bounds: (lower: MoneyOf<C>, upper: MoneyOf<C>),
        by stride: MoneyOf<C>
    ) throws(MoneyStepsParsingError<C>) {
        guard bounds.lower.minorUnits <= bounds.upper.minorUnits else {
            throw .invertedBounds(lowerBound: bounds.lower, upperBound: bounds.upper)
        }
        guard let step = NonZeroInt64(stride.minorUnits) else {
            throw .zeroStride
        }

        try self.init(
            storage: bounds.lower.storage,
            span: bounds.lower.minorUnits ... bounds.upper.minorUnits,
            by: step
        )
    }
}

public extension MoneyOf.Steps where C: CurrencyType {
    /// Creates steps from bounds and a step that may not be valid, such as a server's.
    ///
    /// The same steps as `(bounds.lower...bounds.upper).steps(by:)`, but one call parses every value
    /// and reports every failure in one error. The bounds are named, as for
    /// `ClosedRange(checkedBounds:)`, so a pair that arrives swapped throws rather than counting
    /// down:
    ///
    /// ```swift
    /// let steps = try GBP.Steps(checkedBounds: (lower: minimum, upper: maximum), by: step)
    /// ```
    ///
    /// A negative step starts on the upper bound and counts down to the lower.
    ///
    /// - Parameters:
    ///   - bounds: The lowest step and the highest, the intended lower one first.
    ///   - stride: The gap between neighboring steps. The last gap may be shorter.
    /// - Throws: ``MoneyStepsParsingError/invertedBounds(lowerBound:upperBound:)`` with both bounds
    ///   if the lower is above the upper; otherwise ``MoneyStepsParsingError/zeroStride`` if
    ///   `stride` is zero; otherwise ``MoneyStepsParsingError/tooManySteps`` if there would be more
    ///   steps than `Int` can count.
    @inlinable
    init(
        checkedBounds bounds: (lower: MoneyOf<C>, upper: MoneyOf<C>),
        by stride: MoneyOf<C>
    ) throws(MoneyStepsParsingError<C>) {
        try self.init(parsing: bounds, by: stride)
    }

    /// The lowest step and the highest, as a range, whichever way the steps run.
    ///
    /// ```swift
    /// let limits = GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)
    /// try limits.steps(by: .majorUnits(-100)).bounds   // £10...£250
    /// ```
    @inlinable
    var bounds: ClosedRange<MoneyOf<C>> {
        ClosedRange(
            uncheckedBounds: (
                lower: MoneyOf(unchecked: span.lowerBound, storage: .implied),
                upper: MoneyOf(unchecked: span.upperBound, storage: .implied)
            )
        )
    }

    /// Creates typed steps from runtime ones, if they are in this type's currency.
    ///
    /// - Parameter steps: The steps whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `steps` are in another currency, with
    ///   this type's currency as `lhs`.
    @inlinable
    init(_ steps: Money.Steps) throws(MoneyError) {
        try AnyCurrency.requireMatch(C.currency, steps.storage)

        self.init(unchecked: .implied, span: steps.span, step: steps.step, count: steps.count)
    }

    /// Returns the position of the step nearest an amount.
    ///
    /// An amount between two steps, such as a saved £123.45 on £10 steps, takes the nearer one,
    /// measuring the shorter last gap as it is. An amount beyond the steps takes the nearer end:
    ///
    /// ```swift
    /// steps.index(approximating: saved)   // the nearest step
    /// ```
    ///
    /// A tie goes by default to the step at an even position from the lower bound, so steps that
    /// hold the same amounts break a tie the same way, whichever way they run.
    /// `tiesTo: .awayFromZero` takes the step with the amount's sign instead, the larger in size;
    /// zero counts as positive.
    ///
    /// The nearest step always exists, so this takes a tie-break and can't fail; a rule that names
    /// a direction can, so ``index(approximating:rounding:)`` throws. For an exact match without
    /// rounding, use `firstIndex(of:)`.
    ///
    /// - Parameters:
    ///   - amount: The amount to find a step for.
    ///   - tie: How to choose between two steps the same distance from `amount`.
    /// - Returns: A position in the steps, never `endIndex`.
    /// - Complexity: O(1).
    @inlinable
    func index(
        approximating amount: MoneyOf<C>,
        tiesTo tie: TieBreakingRule = .even
    ) -> Index {
        Index(offset: offset(approximating: amount.minorUnits, tiesTo: tie))
    }

    /// Returns the position of the step on one side of an amount, by a rule that names a direction.
    ///
    /// An amount between two steps, such as a saved £123.45 on £10 steps, has to become one of
    /// them. The rule says which:
    ///
    /// ```swift
    /// try steps.index(approximating: saved, rounding: .down)   // the step at or below `saved`
    /// ```
    ///
    /// `.down` takes the step at or below the amount and `.up` the one at or above. `.towardZero`
    /// takes the neighbor smaller in size and `.awayFromZero` the larger, so when both neighbors
    /// share the amount's sign they act as `.down` or `.up` by that sign. When the neighbors lie
    /// either side of zero, the step can have the other sign: between −£7 and £5, £3 rounds toward
    /// zero to £5 and away from zero to −£7. Where the neighbors are the same size, as −£10 and £10
    /// are, both take the one with the amount's sign; zero counts as positive.
    ///
    /// An amount beyond the steps has one neighbor, the nearer end, and a rule takes it only if it
    /// allows a step on that side. `.towardZero` and `.awayFromZero` act as `.down` or `.up` by the
    /// amount's sign there, and zero counts as positive, so £0 on £5...£17 steps throws under
    /// `.towardZero`. A directed rule can find no step, so this throws; the nearest step always
    /// exists, so ``index(approximating:tiesTo:)`` doesn't.
    ///
    /// - Parameters:
    ///   - amount: The amount to find a step for.
    ///   - rule: Which side of `amount` to take the step from.
    /// - Returns: A position in the steps, never `endIndex`.
    /// - Throws: ``MoneyStepsRoundingError/outOfBounds`` if no step satisfies `rule`, such as under
    ///   `.up` for an amount above the highest step, or `.down` for one below the lowest.
    /// - Complexity: O(1).
    @inlinable
    func index(
        approximating amount: MoneyOf<C>,
        rounding rule: DirectedRoundingRule
    ) throws(MoneyStepsRoundingError<C>) -> Index {
        Index(offset: try offset(approximating: amount.minorUnits, rounding: rule))
    }
}

public extension MoneyOf.Steps where C == AnyCurrency {
    /// Creates steps from runtime bounds and a step that may not be valid, such as a server's.
    ///
    /// Parse a payload once, here, into steps whose currency is checked; using them never throws.
    /// The bounds are named, as for ``ClosedMoneyRange/init(checkedBounds:)``:
    ///
    /// ```swift
    /// let steps = try Money.Steps(
    ///     checkedBounds: (lower: response.minimum, upper: response.maximum),
    ///     by: response.step
    /// )
    /// ```
    ///
    /// A negative step starts on the upper bound and counts down to the lower.
    ///
    /// - Parameters:
    ///   - bounds: The lowest step and the highest, the intended lower one first.
    ///   - stride: The gap between neighboring steps. The last gap may be shorter.
    /// - Throws: ``MoneyStepsParsingError/currencyMismatch(_:)`` with the currency of the upper
    ///   bound, or else of `stride`, if it differs from the lower bound's; otherwise the error the
    ///   typed parse would throw.
    @inlinable
    init(
        checkedBounds bounds: (lower: Money, upper: Money),
        by stride: Money
    ) throws(MoneyStepsParsingError<AnyCurrency>) {
        let currency = bounds.lower.storage
        guard currency == bounds.upper.storage else {
            throw .currencyMismatch(bounds.upper.currency)
        }
        guard currency == stride.storage else {
            throw .currencyMismatch(stride.currency)
        }

        try self.init(parsing: bounds, by: stride)
    }

    /// The lowest step and the highest, as a range in the steps' currency, whichever way the steps
    /// run.
    ///
    /// ```swift
    /// let limits = try pounds(10)...pounds(250)
    /// try limits.steps(by: .minorUnits(-100_00, of: .gbp)).bounds   // GBP 10.00...GBP 250.00
    /// ```
    @inlinable
    var bounds: ClosedMoneyRange {
        ClosedMoneyRange(currency: storage, minorUnits: span)
    }

    /// Creates runtime steps from typed ones, keeping every step and the currency.
    ///
    /// - Parameter typed: The steps whose currency is fixed by their type.
    @inlinable
    init<T: CurrencyType>(_ typed: MoneyOf<T>.Steps) {
        self.init(unchecked: T.currency, span: typed.span, step: typed.step, count: typed.count)
    }

    /// Returns the position of the step nearest a runtime amount, if it is in the steps' currency.
    ///
    /// Rounds as the typed ``index(approximating:tiesTo:)`` does, so only a currency mismatch
    /// fails:
    ///
    /// ```swift
    /// let position = try steps.index(approximating: saved)
    /// ```
    ///
    /// The nearest step always exists, so this takes a tie-break; a rule that names a direction can
    /// find none, so ``index(approximating:rounding:)`` throws ``MoneyStepsRoundingError``.
    ///
    /// - Parameters:
    ///   - amount: The amount to find a step for.
    ///   - tie: How to choose between two steps the same distance from `amount`.
    /// - Returns: A position in the steps, never `endIndex`.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the steps' currency as `lhs`.
    /// - Complexity: O(1).
    @inlinable
    func index(
        approximating amount: Money,
        tiesTo tie: TieBreakingRule = .even
    ) throws(MoneyError) -> Index {
        try AnyCurrency.requireMatch(storage, amount.storage)

        return Index(offset: offset(approximating: amount.minorUnits, tiesTo: tie))
    }

    /// Returns the position of the step on one side of a runtime amount, by a rule that names a
    /// direction, if the amount is in the steps' currency.
    ///
    /// Rounds as the typed ``index(approximating:rounding:)`` does:
    ///
    /// ```swift
    /// let position = try steps.index(approximating: saved, rounding: .down)
    /// ```
    ///
    /// A directed rule can find no step, so this can fail on a matching currency too; the nearest
    /// step always exists, so ``index(approximating:tiesTo:)`` fails only on a mismatch.
    ///
    /// - Parameters:
    ///   - amount: The amount to find a step for.
    ///   - rule: Which side of `amount` to take the step from.
    /// - Returns: A position in the steps, never `endIndex`.
    /// - Throws: ``MoneyStepsRoundingError/currencyMismatch(_:)`` with the currency of `amount` if
    ///   it differs from the steps'; otherwise ``MoneyStepsRoundingError/outOfBounds`` if no step
    ///   satisfies `rule`.
    /// - Complexity: O(1).
    @inlinable
    func index(
        approximating amount: Money,
        rounding rule: DirectedRoundingRule
    ) throws(MoneyStepsRoundingError<AnyCurrency>) -> Index {
        guard amount.storage == storage else {
            throw .currencyMismatch(amount.currency)
        }

        return Index(offset: try offset(approximating: amount.minorUnits, rounding: rule))
    }
}
