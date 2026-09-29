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
    /// `contains(_:)` take constant time however many steps there are.
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

        // The lower and upper bound, in minor units.
        @usableFromInline
        let bounds: ClosedRange<MinorUnits>

        /// The gap between neighboring steps, never longer than the span. Its sign is the direction.
        ///
        /// A negative stride means the steps run from the upper bound down to the lower. The last gap,
        /// onto the far bound, may be shorter. A single step has no neighbor, so its stride is one
        /// minor unit upward.
        public let stride: MoneyOf<C>.Stride

        /// The number of steps, at least one.
        public let count: Int

        // No check: for call sites that computed `count` from `bounds` and a `stride` that is no
        // longer than the span, and one minor unit upward when the span is zero.
        @usableFromInline
        init(
            unchecked bounds: ClosedRange<MinorUnits>,
            stride: MoneyOf<C>.Stride,
            count: Int
        ) {
            self.bounds = bounds
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

            return MoneyOf(unchecked: minorUnits(at: position.offset), storage: stride.amount.storage)
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
    // Counts the steps and settles the stride that a range and a stride give. Offsets from a bound
    // reach 2⁶⁴ − 1 minor units, which `Int64` cannot hold, so the span is measured in `Int128`.
    @inlinable
    init(
        checking bounds: ClosedRange<MoneyOf<C>.MinorUnits>,
        by stride: MoneyOf<C>.Stride
    ) throws(TooManyStepsError) {
        let requested = stride.amount.minorUnits
        let span = Int128(bounds.upperBound) - Int128(bounds.lowerBound)

        // One step has no direction, so every stride gives the same steps. Storing one minor unit
        // upward for all of them keeps equal steps equal, hash included.
        guard span > 0 else {
            let unit = MoneyOf(unchecked: 1, storage: stride.amount.storage)
            self.init(unchecked: bounds, stride: MoneyOf.Stride(unchecked: unit), count: 1)
            return
        }

        let magnitude = Int128(requested.magnitude)
        guard let count = Int(exactly: (span - 1) / magnitude + 2) else {
            throw TooManyStepsError()
        }

        // A stride longer than the span gives the same two steps as the span itself, so it is
        // shortened to it: equal steps then compare and hash equal. The shortened stride is at most
        // the requested one, so it fits `Int64`.
        let shortened = Swift.min(magnitude, span)
        let settled = Int64(truncatingIfNeeded: requested < 0 ? -shortened : shortened)
        let amount = MoneyOf(unchecked: settled, storage: stride.amount.storage)
        self.init(unchecked: bounds, stride: MoneyOf.Stride(unchecked: amount), count: count)
    }

    // The bound the steps start on, and the one they always end on.
    @inlinable
    var nearBound: MoneyOf<C>.MinorUnits {
        stride.amount.minorUnits > 0 ? bounds.lowerBound : bounds.upperBound
    }

    @inlinable
    var farBound: MoneyOf<C>.MinorUnits {
        stride.amount.minorUnits > 0 ? bounds.upperBound : bounds.lowerBound
    }

    // Every offset before the last is strictly between the bounds, so the sum fits `Int64`.
    @inlinable
    func minorUnits(at offset: Int) -> MoneyOf<C>.MinorUnits {
        guard offset != count - 1 else {
            return farBound
        }

        return Int64(truncatingIfNeeded: Int128(nearBound) + Int128(offset) * Int128(stride.amount.minorUnits))
    }

    // The offset of the step equal to `element`, or `nil` if it is in another currency or not a step.
    @inlinable
    func offset(of element: MoneyOf<C>) -> Int? {
        guard element.storage == stride.amount.storage else {
            return nil
        }
        guard element.minorUnits != farBound else {
            return count - 1
        }

        let distance = Int128(element.minorUnits) - Int128(nearBound)
        let (steps, remainder) = distance.quotientAndRemainder(dividingBy: Int128(stride.amount.minorUnits))
        guard remainder == 0, steps >= 0, steps < Int128(count - 1) else {
            return nil
        }

        return Int(truncatingIfNeeded: steps)
    }
}

public extension MoneyOf.Steps where C: CurrencyType {
    /// Creates typed steps from runtime ones, if they are in this type's currency.
    ///
    /// - Parameter steps: The steps whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `steps` are in another currency, with
    ///   this type's currency as `lhs`.
    @inlinable
    init(_ steps: Money.Steps) throws(MoneyError) {
        self.init(unchecked: steps.bounds, stride: try MoneyOf.Stride(steps.stride), count: steps.count)
    }
}

public extension MoneyOf.Steps where C == AnyCurrency {
    /// Creates runtime steps from typed ones, keeping every step and the currency.
    ///
    /// - Parameter typed: The steps whose currency is fixed by their type.
    @inlinable
    init<T: CurrencyType>(_ typed: MoneyOf<T>.Steps) {
        self.init(unchecked: typed.bounds, stride: Money.Stride(typed.stride), count: typed.count)
    }
}
