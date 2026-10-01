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
    /// work out an amount's position from the bounds and the stride rather than stepping through,
    /// and `index(approximating:tiesTo:)` and `index(approximating:rounding:)`, which round an
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

    /// Returns how many steps from the lower bound the step a number of steps from the first is.
    ///
    /// - Parameter offset: How many steps the step is from the first, from zero up to `count - 1`.
    /// - Returns: `offset` for steps that run upward; otherwise its distance from the last step.
    @inlinable
    func positionFromLowerBound(ofOffset offset: Int) -> Int {
        switch direction {
        case .upward:
            offset
        case .downward:
            count - 1 - offset
        }
    }

    /// Returns how far an amount is from the near bound, toward the far one.
    ///
    /// - Parameter minorUnits: The amount's minor units, from the lowest step to the highest.
    /// - Returns: The distance in minor units, which is at most the span's width.
    @inlinable
    func distanceFromNearBound(to minorUnits: MoneyOf<C>.MinorUnits) -> UInt64 {
        // The width reaches 2⁶⁴ − 1, which `Int64` cannot hold, but wrapping gives its bit pattern.
        switch direction {
        case .upward:
            UInt64(bitPattern: minorUnits &- span.lowerBound)
        case .downward:
            UInt64(bitPattern: span.upperBound &- minorUnits)
        }
    }

    /// Returns the steps either side of an amount, and how far the amount is from each.
    ///
    /// An amount on a step has that step on both sides, at no distance from either. Otherwise the
    /// two are neighbors, and the distances add up to the gap between them.
    ///
    /// - Parameter minorUnits: The amount's minor units, from the lowest step to the highest.
    /// - Returns: The offsets of the highest step at or below the amount and the lowest at or
    ///   above, and the minor units from the amount to each.
    /// - Complexity: O(1).
    @inlinable
    func neighbors(
        of minorUnits: MoneyOf<C>.MinorUnits
    ) -> (below: Int, above: Int, toBelow: UInt64, toAbove: UInt64) {
        guard minorUnits != farBound else {
            return (count - 1, count - 1, 0, 0)
        }

        let gap = step.rawValue.magnitude
        let (behind, remainder) = distanceFromNearBound(to: minorUnits).quotientAndRemainder(dividingBy: gap)
        let offset = Int(truncatingIfNeeded: behind)
        guard remainder != 0 else {
            return (offset, offset, 0, 0)
        }

        // The step ahead is a whole stride on, unless it is the far bound, which may be nearer.
        let width = Swift.min(gap, UInt64(bitPattern: span.upperBound &- span.lowerBound) - behind * gap)
        switch direction {
        case .upward:
            return (offset, offset + 1, remainder, width - remainder)
        case .downward:
            return (offset + 1, offset, width - remainder, remainder)
        }
    }

    /// Returns how many steps from the first the step nearest an amount is.
    ///
    /// - Parameters:
    ///   - minorUnits: The amount's minor units, in the steps' currency.
    ///   - tie: How to choose between two steps the same distance away.
    /// - Returns: The offset of the nearest step, the nearer end for an amount beyond the steps.
    /// - Complexity: O(1).
    @inlinable
    func offset(
        nearest minorUnits: MoneyOf<C>.MinorUnits,
        tiesTo tie: TieBreakingRule
    ) -> Int {
        let beside = neighbors(of: Swift.min(Swift.max(minorUnits, span.lowerBound), span.upperBound))
        guard beside.toBelow == beside.toAbove else {
            return beside.toBelow < beside.toAbove ? beside.below : beside.above
        }

        switch (tie, Sign(of: minorUnits)) {
        case (.even, _):
            return Parity(of: positionFromLowerBound(ofOffset: beside.below)) == .even ? beside.below : beside.above
        case (.awayFromZero, .positive):
            return beside.above
        case (.awayFromZero, .negative):
            return beside.below
        }
    }

    /// Returns how many steps from the first the step an amount rounds to is, if a step satisfies
    /// the rule.
    ///
    /// - Parameters:
    ///   - minorUnits: The amount's minor units, in the steps' currency.
    ///   - rule: Which side of the amount to take the step from.
    /// - Returns: The offset of the step `rule` picks.
    /// - Throws: ``MoneyStepsRoundingError/outOfBounds`` if the amount is beyond the steps and `rule`
    ///   rules out the only step beside it.
    /// - Complexity: O(1).
    @inlinable
    func offset(
        approximating minorUnits: MoneyOf<C>.MinorUnits,
        rounding rule: DirectedRoundingRule
    ) throws(MoneyStepsRoundingError<C>) -> Int {
        // Beyond the steps there is one neighbor and no second size to compare, so `.towardZero`
        // and `.awayFromZero` look below or above by the amount's sign.
        let sign = Sign(of: minorUnits)
        switch (rule, sign) {
        case (.down, _), (.towardZero, .positive), (.awayFromZero, .negative):
            guard minorUnits >= span.lowerBound else {
                throw .outOfBounds
            }
        case (.up, _), (.towardZero, .negative), (.awayFromZero, .positive):
            guard minorUnits <= span.upperBound else {
                throw .outOfBounds
            }
        }

        let inside = Swift.min(Swift.max(minorUnits, span.lowerBound), span.upperBound)
        let beside = neighbors(of: inside)

        // Both neighbors are steps, so they fit `Int64` and wrapping lands on them exactly, even
        // where a distance is too large for `Int64`.
        let belowSize = (inside &- Int64(bitPattern: beside.toBelow)).magnitude
        let aboveSize = (inside &+ Int64(bitPattern: beside.toAbove)).magnitude
        switch (rule, sign) {
        case (.down, _):
            return beside.below
        case (.up, _):
            return beside.above
        case (.towardZero, _) where belowSize != aboveSize:
            return belowSize < aboveSize ? beside.below : beside.above
        case (.awayFromZero, _) where belowSize != aboveSize:
            return belowSize > aboveSize ? beside.below : beside.above
        // Neighbors of equal size, such as −£10 and £10, give the one with the amount's sign.
        case (.towardZero, .positive), (.awayFromZero, .positive):
            return beside.above
        case (.towardZero, .negative), (.awayFromZero, .negative):
            return beside.below
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
    /// measuring the shorter last gap as it is. An amount beyond the steps takes the nearer end, so
    /// this never fails:
    ///
    /// ```swift
    /// steps.index(approximating: saved)   // the nearest step
    /// ```
    ///
    /// A tie goes by default to the step at an even position from the lower bound, so it falls the
    /// same way whichever way the steps run. `tiesTo: .awayFromZero` takes the step with the
    /// amount's sign instead, the larger in size; zero counts as positive.
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
        Index(offset: offset(nearest: amount.minorUnits, tiesTo: tie))
    }

    /// Returns the position of the step on one side of an amount, by a rule that names a direction.
    ///
    /// An amount between two steps, such as a saved £123.45 on £10 steps, has to become one of them.
    /// The rule says which:
    ///
    /// ```swift
    /// try steps.index(approximating: saved, rounding: .down)   // the highest step at or below
    /// ```
    ///
    /// `.down` takes the step at or below the amount and `.up` the one at or above. `.towardZero`
    /// takes the neighbor smaller in size and `.awayFromZero` the larger, so when both neighbors share
    /// the amount's sign they act as `.down` or `.up` by that sign. When the neighbors lie either side
    /// of zero, the step can have the other sign: between −£7 and £5, £3 rounds toward zero to £5 and
    /// away from zero to −£7. Where the neighbors are the same size, as −£10 and £10 are, both take
    /// the one with the amount's sign; zero counts as positive.
    ///
    /// An amount beyond the steps has one neighbor, the nearer end, and a rule takes it only if it
    /// allows a step on that side. `.towardZero` and `.awayFromZero` act as `.down` or `.up` by the
    /// amount's sign there. A directed rule can find no step, so this throws; the nearest step
    /// always exists, so ``index(approximating:tiesTo:)`` doesn't.
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
    /// Rounds as the typed `index(approximating:tiesTo:)` does, so only a currency mismatch fails:
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

        return Index(offset: offset(nearest: amount.minorUnits, tiesTo: tie))
    }

    /// Returns the position of the step on one side of a runtime amount, by a rule that names a
    /// direction, if the amount is in the steps' currency.
    ///
    /// Rounds as the typed `index(approximating:rounding:)` does:
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
