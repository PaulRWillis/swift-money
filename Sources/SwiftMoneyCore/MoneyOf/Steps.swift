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
    /// Steps are a random-access collection, so `count`, the subscript, `firstIndex(of:)` and
    /// `contains(_:)` take constant time however many steps there are. So does
    /// `index(for:rounding:)`, which rounds an amount between two steps to one of them.
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

        // The lowest step, never above `upperBound`, and in the currency of `stride`.
        @usableFromInline
        let lowerBound: MoneyOf<C>

        // The highest step, in the currency of `stride`.
        @usableFromInline
        let upperBound: MoneyOf<C>

        /// The gap between neighboring steps, never longer than the span. Its sign is the direction.
        ///
        /// A negative stride means the steps run from the upper bound down to the lower. The last gap,
        /// onto the far bound, may be shorter. A single step has no neighbor, so its stride is one
        /// minor unit upward.
        public let stride: MoneyOf<C>.Stride

        /// The number of steps, at least one.
        public let count: Int

        // No check: for call sites that computed `count` from ordered bounds and a `stride` that is no
        // longer than the span, and one minor unit upward when the span is zero, all in one currency.
        @usableFromInline
        init(
            unchecked lowerBound: MoneyOf<C>,
            through upperBound: MoneyOf<C>,
            stride: MoneyOf<C>.Stride,
            count: Int
        ) {
            self.lowerBound = lowerBound
            self.upperBound = upperBound
            self.stride = stride
            self.count = count
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
    // Counts the steps and settles the stride that ordered bounds and a stride, all in one currency,
    // give. The span reaches 2⁶⁴ − 1 minor units, which `Int64` cannot hold but `UInt64` can, and an
    // `Int128` divide is a library call.
    @inlinable
    init(
        checking lowerBound: MoneyOf<C>,
        through upperBound: MoneyOf<C>,
        by stride: MoneyOf<C>.Stride
    ) throws(TooManyStepsError) {
        let requested = stride.amount.minorUnits
        let span = UInt64(bitPattern: upperBound.minorUnits &- lowerBound.minorUnits)

        // One step has no direction, so every stride gives the same steps. Storing one minor unit
        // upward for all of them keeps equal steps equal, hash included.
        guard span > 0 else {
            let unit = MoneyOf(unchecked: 1, storage: stride.amount.storage)
            self.init(unchecked: lowerBound, through: upperBound, stride: MoneyOf.Stride(unchecked: unit), count: 1)
            return
        }

        let magnitude = requested.magnitude
        let (steps, overflow) = ((span &- 1) / magnitude).addingReportingOverflow(2)
        guard !overflow, let count = Int(exactly: steps) else {
            throw TooManyStepsError()
        }

        // A stride longer than the span gives the same two steps as the span itself, so it is
        // shortened to it: equal steps then compare and hash equal. The shortened stride is at most
        // the requested one, so its bit pattern, negated for a downward stride, fits `Int64`.
        let shortened = Swift.min(magnitude, span)
        let settled = Int64(bitPattern: requested < 0 ? 0 &- shortened : shortened)
        let amount = MoneyOf(unchecked: settled, storage: stride.amount.storage)
        self.init(unchecked: lowerBound, through: upperBound, stride: MoneyOf.Stride(unchecked: amount), count: count)
    }

    // The bound the steps start on, and the one they always end on.
    @inlinable
    var nearBound: MoneyOf<C> {
        stride.amount.minorUnits > 0 ? lowerBound : upperBound
    }

    @inlinable
    var farBound: MoneyOf<C> {
        stride.amount.minorUnits > 0 ? upperBound : lowerBound
    }

    // Every offset before the last is strictly between the bounds, so the step fits `Int64` even when
    // the product alone does not: wrapping arithmetic works modulo 2⁶⁴ and lands on it exactly.
    @inlinable
    func amount(at offset: Int) -> MoneyOf<C> {
        guard offset != count &- 1 else {
            return farBound
        }

        let near = nearBound
        let minorUnits = near.minorUnits &+ Int64(truncatingIfNeeded: offset) &* stride.amount.minorUnits

        return MoneyOf(unchecked: minorUnits, storage: near.storage)
    }

    // The offset of the step equal to `element`, or `nil` if it is in another currency or not a step.
    // Short of the far bound, the distance from the near one is below the span, so `UInt64` holds it
    // and a whole number of strides is a step before the last, which `Int` counts.
    @inlinable
    func offset(of element: MoneyOf<C>) -> Int? {
        let minorUnits = element.minorUnits
        let lower = lowerBound.minorUnits
        let upper = upperBound.minorUnits
        guard element.storage == stride.amount.storage, lower <= minorUnits, minorUnits <= upper else {
            return nil
        }
        guard minorUnits != farBound.minorUnits else {
            return count &- 1
        }

        let ascending = stride.amount.minorUnits > 0
        let travelled = UInt64(bitPattern: ascending ? minorUnits &- lower : upper &- minorUnits)
        let (steps, remainder) = travelled.quotientAndRemainder(dividingBy: stride.amount.minorUnits.magnitude)

        return remainder == 0 ? Int(truncatingIfNeeded: steps) : nil
    }

    // The offset of the step that an amount in the steps' currency rounds to. Distances are measured
    // from the near bound toward the far one: strictly between the bounds they are below 2⁶⁴, so
    // `UInt64` holds them, and a division finds the two steps either side without walking.
    @inlinable
    func offset(
        rounding minorUnits: MoneyOf<C>.MinorUnits,
        _ rule: RoundingRule
    ) -> Int {
        let ascending = stride.amount.minorUnits > 0
        let lower = lowerBound.minorUnits
        let upper = upperBound.minorUnits
        guard minorUnits > lower else {
            return ascending ? 0 : count - 1
        }
        guard minorUnits < upper else {
            return ascending ? count - 1 : 0
        }

        let gap = stride.amount.minorUnits.magnitude
        let span = UInt64(bitPattern: upper &- lower)
        let travelled = UInt64(bitPattern: ascending ? minorUnits &- lower : upper &- minorUnits)
        let (behind, remainder) = travelled.quotientAndRemainder(dividingBy: gap)
        guard remainder != 0 else {
            return Int(truncatingIfNeeded: behind)
        }

        // The step ahead is a whole stride on, unless it is the far bound, which may be nearer.
        let width = Swift.min(gap, span - behind * gap)

        // The rounding rules work from the step toward zero, as for a quotient: the lower one for a
        // positive amount, the higher for a negative. Zero counts as positive, as in `Sign(of:)`, which
        // is generic and not inlinable, so calling it here would cost an unspecialized call.
        let sign: Sign = minorUnits < 0 ? .negative : .positive
        let towardZeroIsBehind = (sign == .positive) == ascending
        let towardZero = Int(truncatingIfNeeded: towardZeroIsBehind ? behind : behind + 1)
        let awayFromZero = towardZeroIsBehind ? towardZero + 1 : towardZero - 1
        let dropped = towardZeroIsBehind ? remainder : width - remainder

        // When the step toward zero lies past it, the neighbors are either side of zero, and
        // `.towardZero` and `.awayFromZero` take the smaller or the larger in size rather than follow
        // the sign. Neighbors of equal size give the one on the amount's side of zero.
        let size = minorUnits.magnitude
        if size < dropped, rule == .towardZero || rule == .awayFromZero {
            let pastZero = dropped - size
            let sameSide = size + (width - dropped)
            let takesPastZero = rule == .towardZero ? pastZero < sameSide : pastZero > sameSide

            return takesPastZero ? towardZero : awayFromZero
        }

        let step = rule.step(
            dropping: DroppedFraction(remainder: dropped, divisor: width),
            sign: sign,
            truncated: Parity(of: towardZero)
        )

        return step == .awayFromZero ? awayFromZero : towardZero
    }

    // Parses bounds and a step already known to share a currency, so the typed and runtime parses
    // report the same failures in the same order.
    @inlinable
    init(
        parsing lowerBound: MoneyOf<C>,
        through upperBound: MoneyOf<C>,
        by stride: MoneyOf<C>
    ) throws(StepsError<C>) {
        guard lowerBound.minorUnits <= upperBound.minorUnits else {
            throw .invertedBounds(InvertedBoundsError(lowerBound: lowerBound, upperBound: upperBound))
        }
        guard let stride = MoneyOf.Stride(exactly: stride) else {
            throw .zeroStride
        }

        do throws(TooManyStepsError) {
            try self.init(checking: lowerBound, through: upperBound, by: stride)
        } catch {
            throw .tooManySteps(error)
        }
    }
}

public extension MoneyOf.Steps where C: CurrencyType {
    /// Creates steps from bounds and a step that may not be valid, such as a server's.
    ///
    /// The same steps as `(lowerBound...upperBound).steps(by:)`, but one call parses every value and
    /// reports every failure in one error:
    ///
    /// ```swift
    /// let steps = try GBP.Steps(from: response.minimum, through: response.maximum, by: response.step)
    /// ```
    ///
    /// A negative step starts on `upperBound` and counts down to `lowerBound`.
    ///
    /// - Parameters:
    ///   - lowerBound: The lowest step.
    ///   - upperBound: The highest step.
    ///   - stride: The gap between neighboring steps. The last gap may be shorter.
    /// - Throws: ``StepsError/invertedBounds(_:)`` if `lowerBound` is above `upperBound`; otherwise
    ///   ``StepsError/zeroStride`` if `stride` is zero; otherwise ``StepsError/tooManySteps(_:)`` if
    ///   there would be more steps than `Int` can count.
    @inlinable
    init(
        from lowerBound: MoneyOf<C>,
        through upperBound: MoneyOf<C>,
        by stride: MoneyOf<C>
    ) throws(StepsError<C>) {
        try self.init(parsing: lowerBound, through: upperBound, by: stride)
    }

    /// Creates typed steps from runtime ones, if they are in this type's currency.
    ///
    /// - Parameter steps: The steps whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `steps` are in another currency, with
    ///   this type's currency as `lhs`.
    @inlinable
    init(_ steps: Money.Steps) throws(MoneyError) {
        let stride = try MoneyOf.Stride(steps.stride)
        self.init(
            unchecked: MoneyOf(unchecked: steps.lowerBound.minorUnits, storage: .implied),
            through: MoneyOf(unchecked: steps.upperBound.minorUnits, storage: .implied),
            stride: stride,
            count: steps.count
        )
    }

    /// Returns the position of the step an amount rounds to.
    ///
    /// An amount between two steps, such as a saved £123.45 on £10 steps, has to become one of them.
    /// The rule says which:
    ///
    /// ```swift
    /// steps.index(for: saved)                     // the nearest step, ties to the even index
    /// steps.index(for: saved, rounding: .down)    // the highest step at or below `saved`
    /// ```
    ///
    /// `.down` takes the step at or below the amount and `.up` the one at or above. `.towardZero`
    /// takes the neighbor smaller in size and `.awayFromZero` the larger, so when both neighbors share
    /// the amount's sign they act as `.down` or `.up` by that sign. When the neighbors lie either side
    /// of zero, the step can have the other sign: between −£7 and £5, £3 rounds toward zero to £5 and
    /// away from zero to −£7. The two nearest rules measure the distance to each neighbor, the shorter
    /// last gap included: `.toNearestOrEven` breaks a tie toward the even index, and
    /// `.toNearestOrAwayFromZero` toward the step larger in size. Where the neighbors are the same
    /// size, as −£10 and £10 are, the rules that name zero take the one with the amount's sign; zero
    /// counts as positive. An amount beyond the steps takes the nearer end under every rule. For an
    /// exact match without rounding, use `firstIndex(of:)`.
    ///
    /// - Parameters:
    ///   - amount: The amount to find a step for.
    ///   - rule: How to choose between the two steps either side of `amount`.
    /// - Returns: A position in the steps, never `endIndex`.
    /// - Complexity: O(1).
    @inlinable
    func index(
        for amount: MoneyOf<C>,
        rounding rule: RoundingRule = .toNearestOrEven
    ) -> Index {
        Index(offset: offset(rounding: amount.minorUnits, rule))
    }
}

public extension MoneyOf.Steps where C == AnyCurrency {
    /// Creates steps from runtime bounds and a step that may not be valid, such as a server's.
    ///
    /// Parse a payload once, here, into steps whose currency is checked; using them never throws:
    ///
    /// ```swift
    /// let steps = try Money.Steps(from: response.minimum, through: response.maximum, by: response.step)
    /// ```
    ///
    /// A negative step starts on `upperBound` and counts down to `lowerBound`.
    ///
    /// - Parameters:
    ///   - lowerBound: The lowest step.
    ///   - upperBound: The highest step.
    ///   - stride: The gap between neighboring steps. The last gap may be shorter.
    /// - Throws: ``CurrencyCheckedError/currencyMismatch(lhs:rhs:)`` if `upperBound`, or else
    ///   `stride`, is in another currency, with `lowerBound`'s as `lhs`; otherwise
    ///   ``CurrencyCheckedError/failure(_:)`` with the ``StepsError`` the typed parse would throw.
    @inlinable
    init(
        from lowerBound: Money,
        through upperBound: Money,
        by stride: Money
    ) throws(CurrencyCheckedError<StepsError<AnyCurrency>>) {
        let currency = lowerBound.storage
        guard currency == upperBound.storage else {
            throw .currencyMismatch(lhs: currency, rhs: upperBound.storage)
        }
        guard currency == stride.storage else {
            throw .currencyMismatch(lhs: currency, rhs: stride.storage)
        }

        do throws(StepsError<AnyCurrency>) {
            try self.init(parsing: lowerBound, through: upperBound, by: stride)
        } catch {
            throw .failure(error)
        }
    }

    /// Creates runtime steps from typed ones, keeping every step and the currency.
    ///
    /// - Parameter typed: The steps whose currency is fixed by their type.
    @inlinable
    init<T: CurrencyType>(_ typed: MoneyOf<T>.Steps) {
        self.init(
            unchecked: Money(typed.lowerBound),
            through: Money(typed.upperBound),
            stride: Money.Stride(typed.stride),
            count: typed.count
        )
    }

    /// Returns the position of the step a runtime amount rounds to, if it is in the steps' currency.
    ///
    /// Rounds as the typed `index(for:rounding:)` does:
    ///
    /// ```swift
    /// let position = try steps.index(for: saved, rounding: .down)
    /// ```
    ///
    /// - Parameters:
    ///   - amount: The amount to find a step for.
    ///   - rule: How to choose between the two steps either side of `amount`.
    /// - Returns: A position in the steps, never `endIndex`.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the steps' currency as `lhs`.
    /// - Complexity: O(1).
    @inlinable
    func index(
        for amount: Money,
        rounding rule: RoundingRule = .toNearestOrEven
    ) throws(MoneyError) -> Index {
        try AnyCurrency.requireMatch(stride.amount.storage, amount.storage)

        return Index(offset: offset(rounding: amount.minorUnits, rule))
    }
}
