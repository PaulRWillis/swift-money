public extension MoneyOf.Steps {
    /// The chosen one of a set of steps, so always in their currency and on a step.
    ///
    /// What a slider or a stepper binds to. Build one from a saved amount, which is rounded onto a
    /// step, and change it by selecting another step:
    ///
    /// ```swift
    /// let selection = GBP.Steps.Selection(approximating: saved, in: steps)   // the nearest step
    /// let top = selection.selecting(3)   // the fourth step, or nil if none
    /// ```
    ///
    /// A selection is immutable: selecting returns a new one, which a binding assigns.
    ///
    /// Two selections are equal when they hold equal steps and the same position.
    struct Selection: Equatable, Hashable, Sendable {
        /// The steps chosen among.
        public let steps: MoneyOf<C>.Steps

        /// The position of the chosen step, always a position in ``steps``.
        public let index: Index

        /// Creates a selection without checking that the position is in the steps.
        ///
        /// - Parameters:
        ///   - steps: The steps chosen among.
        ///   - index: The position of the chosen step, from `steps` and before its `endIndex`.
        @usableFromInline
        init(
            unchecked steps: MoneyOf<C>.Steps,
            index: Index
        ) {
            self.steps = steps
            self.index = index
        }

        /// The chosen step.
        @inlinable
        public var amount: MoneyOf<C> {
            steps.amount(at: index.offset)
        }

        /// Returns the selection of another position in the same steps, if it is one.
        ///
        /// An index from another set of steps that happens to be in range cannot be told apart, as
        /// for `Array`; use indices from ``steps``.
        ///
        /// - Parameter index: The position to choose.
        /// - Returns: `nil` if `index` is not a position in ``steps``, such as `endIndex`.
        @inlinable
        public func selecting(_ index: Index) -> Self? {
            guard index.offset >= 0, index.offset < steps.count else {
                return nil
            }

            return Self(unchecked: steps, index: index)
        }
    }
}

public extension MoneyOf.Steps.Selection where C: CurrencyType {
    /// Creates the selection of the step nearest an amount.
    ///
    /// Rounds as ``MoneyOf/Steps/index(approximating:tiesTo:)`` does, so an amount beyond the steps
    /// selects the nearer end. The nearest step always exists, so this takes a tie-break and can't
    /// fail.
    ///
    /// - Parameters:
    ///   - amount: The amount to select, such as a saved one.
    ///   - steps: The steps to choose among.
    ///   - tie: How to choose between two steps the same distance from `amount`.
    @inlinable
    init(
        approximating amount: MoneyOf<C>,
        in steps: MoneyOf<C>.Steps,
        tiesTo tie: TieBreakingRule = .even
    ) {
        self.init(unchecked: steps, index: steps.index(approximating: amount, tiesTo: tie))
    }

    /// Creates the selection of the step on one side of an amount, by a rule that names a
    /// direction.
    ///
    /// Rounds as ``MoneyOf/Steps/index(approximating:rounding:)`` does. A directed rule can find no
    /// step, so this throws.
    ///
    /// - Parameters:
    ///   - amount: The amount to select, such as a saved one.
    ///   - steps: The steps to choose among.
    ///   - rule: Which side of `amount` to take the step from.
    /// - Throws: ``MoneyStepsRoundingError/outOfBounds`` if no step satisfies `rule`.
    @inlinable
    init(
        approximating amount: MoneyOf<C>,
        in steps: MoneyOf<C>.Steps,
        rounding rule: DirectedRoundingRule
    ) throws(MoneyStepsRoundingError<C>) {
        self.init(unchecked: steps, index: try steps.index(approximating: amount, rounding: rule))
    }

    /// Returns the selection of the step nearest an amount, in the same steps.
    ///
    /// The nearest step always exists, so this takes a tie-break and can't fail.
    ///
    /// - Parameters:
    ///   - amount: The amount to select.
    ///   - tie: How to choose between two steps the same distance from `amount`.
    /// - Returns: The selection of the step nearest `amount`, in ``steps``.
    @inlinable
    func selecting(
        approximating amount: MoneyOf<C>,
        tiesTo tie: TieBreakingRule = .even
    ) -> Self {
        Self(approximating: amount, in: steps, tiesTo: tie)
    }

    /// Returns the selection of the step on one side of an amount, by a rule that names a
    /// direction, in the same steps.
    ///
    /// A directed rule can find no step, so this throws.
    ///
    /// - Parameters:
    ///   - amount: The amount to select.
    ///   - rule: Which side of `amount` to take the step from.
    /// - Returns: The selection of the step `rule` takes, in ``steps``.
    /// - Throws: ``MoneyStepsRoundingError/outOfBounds`` if no step satisfies `rule`.
    @inlinable
    func selecting(
        approximating amount: MoneyOf<C>,
        rounding rule: DirectedRoundingRule
    ) throws(MoneyStepsRoundingError<C>) -> Self {
        try Self(approximating: amount, in: steps, rounding: rule)
    }

    /// Creates a typed selection from a runtime one, if it is in this type's currency.
    ///
    /// - Parameter selection: The selection whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `selection` is in another currency,
    ///   with this type's currency as `lhs`.
    @inlinable
    init(_ selection: Money.Steps.Selection) throws(MoneyError) {
        self.init(unchecked: try MoneyOf.Steps(selection.steps), index: MoneyOf.Steps.Index(offset: selection.index.offset))
    }
}

public extension MoneyOf.Steps.Selection where C == AnyCurrency {
    /// Creates the selection of the step nearest a runtime amount, if it is in the steps' currency.
    ///
    /// ```swift
    /// let selection = try Money.Steps.Selection(approximating: saved, in: steps)
    /// ```
    ///
    /// The nearest step always exists, so this takes a tie-break and fails only on a mismatch.
    ///
    /// - Parameters:
    ///   - amount: The amount to select, such as a saved one.
    ///   - steps: The steps to choose among.
    ///   - tie: How to choose between two steps the same distance from `amount`.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the steps' currency as `lhs`.
    @inlinable
    init(
        approximating amount: Money,
        in steps: Money.Steps,
        tiesTo tie: TieBreakingRule = .even
    ) throws(MoneyError) {
        self.init(unchecked: steps, index: try steps.index(approximating: amount, tiesTo: tie))
    }

    /// Creates the selection of the step on one side of a runtime amount, by a rule that names a
    /// direction, if the amount is in the steps' currency.
    ///
    /// A directed rule can find no step, so this can fail on a matching currency too.
    ///
    /// - Parameters:
    ///   - amount: The amount to select, such as a saved one.
    ///   - steps: The steps to choose among.
    ///   - rule: Which side of `amount` to take the step from.
    /// - Throws: ``MoneyStepsRoundingError/currencyMismatch(_:)`` with the currency of `amount` if
    ///   it differs from the steps'; otherwise ``MoneyStepsRoundingError/outOfBounds`` if no step
    ///   satisfies `rule`.
    @inlinable
    init(
        approximating amount: Money,
        in steps: Money.Steps,
        rounding rule: DirectedRoundingRule
    ) throws(MoneyStepsRoundingError<AnyCurrency>) {
        self.init(unchecked: steps, index: try steps.index(approximating: amount, rounding: rule))
    }

    /// Returns the selection of the step nearest a runtime amount, in the same steps.
    ///
    /// The nearest step always exists, so this takes a tie-break and fails only on a mismatch.
    ///
    /// - Parameters:
    ///   - amount: The amount to select.
    ///   - tie: How to choose between two steps the same distance from `amount`.
    /// - Returns: The selection of the step nearest `amount`, in ``steps``.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the steps' currency as `lhs`.
    @inlinable
    func selecting(
        approximating amount: Money,
        tiesTo tie: TieBreakingRule = .even
    ) throws(MoneyError) -> Self {
        try Self(approximating: amount, in: steps, tiesTo: tie)
    }

    /// Returns the selection of the step on one side of a runtime amount, by a rule that names a
    /// direction, in the same steps.
    ///
    /// A directed rule can find no step, so this can fail on a matching currency too.
    ///
    /// - Parameters:
    ///   - amount: The amount to select.
    ///   - rule: Which side of `amount` to take the step from.
    /// - Returns: The selection of the step `rule` takes, in ``steps``.
    /// - Throws: ``MoneyStepsRoundingError/currencyMismatch(_:)`` with the currency of `amount` if
    ///   it differs from the steps'; otherwise ``MoneyStepsRoundingError/outOfBounds`` if no step
    ///   satisfies `rule`.
    @inlinable
    func selecting(
        approximating amount: Money,
        rounding rule: DirectedRoundingRule
    ) throws(MoneyStepsRoundingError<AnyCurrency>) -> Self {
        try Self(approximating: amount, in: steps, rounding: rule)
    }

    /// Creates a runtime selection from a typed one, keeping its steps and position.
    ///
    /// - Parameter typed: The selection whose currency is fixed by its type.
    @inlinable
    init<T: CurrencyType>(_ typed: MoneyOf<T>.Steps.Selection) {
        self.init(unchecked: Money.Steps(typed.steps), index: Money.Steps.Index(offset: typed.index.offset))
    }
}
