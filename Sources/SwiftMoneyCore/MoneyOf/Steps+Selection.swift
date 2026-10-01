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

        // No check: for call sites whose `index` came from `steps` and is before its `endIndex`.
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
    /// Rounds as ``MoneyOf/Steps/index(approximating:)`` does, so an amount beyond the steps
    /// selects the nearer end.
    ///
    /// - Parameters:
    ///   - amount: The amount to select, such as a saved one.
    ///   - steps: The steps to choose among.
    @inlinable
    init(
        approximating amount: MoneyOf<C>,
        in steps: MoneyOf<C>.Steps
    ) {
        self.init(unchecked: steps, index: steps.index(approximating: amount))
    }

    /// Creates the selection of the step an amount rounds to by a rule.
    ///
    /// Rounds as ``MoneyOf/Steps/index(approximating:rounding:)`` does.
    ///
    /// - Parameters:
    ///   - amount: The amount to select, such as a saved one.
    ///   - steps: The steps to choose among.
    ///   - rule: How to choose between the two steps either side of `amount`.
    /// - Throws: ``MoneyStepsRoundingError/outOfBounds`` if no step satisfies `rule`.
    @inlinable
    init(
        approximating amount: MoneyOf<C>,
        in steps: MoneyOf<C>.Steps,
        rounding rule: RoundingRule
    ) throws(MoneyStepsRoundingError<C>) {
        self.init(unchecked: steps, index: try steps.index(approximating: amount, rounding: rule))
    }

    /// Returns the selection of the step nearest an amount, in the same steps.
    ///
    /// - Parameter amount: The amount to select.
    @inlinable
    func selecting(approximating amount: MoneyOf<C>) -> Self {
        Self(approximating: amount, in: steps)
    }

    /// Returns the selection of the step an amount rounds to by a rule, in the same steps.
    ///
    /// - Parameters:
    ///   - amount: The amount to select.
    ///   - rule: How to choose between the two steps either side of `amount`.
    /// - Throws: ``MoneyStepsRoundingError/outOfBounds`` if no step satisfies `rule`.
    @inlinable
    func selecting(
        approximating amount: MoneyOf<C>,
        rounding rule: RoundingRule
    ) throws(MoneyStepsRoundingError<C>) -> Self {
        try Self(approximating: amount, in: steps, rounding: rule)
    }

    /// Creates a typed selection from a runtime one, if it is in this type's currency.
    ///
    /// - Parameter selection: The selection whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `selection` is in another currency, with
    ///   this type's currency as `lhs`.
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
    /// - Parameters:
    ///   - amount: The amount to select, such as a saved one.
    ///   - steps: The steps to choose among.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the steps' currency as `lhs`.
    @inlinable
    init(
        approximating amount: Money,
        in steps: Money.Steps
    ) throws(MoneyError) {
        self.init(unchecked: steps, index: try steps.index(approximating: amount))
    }

    /// Creates the selection of the step a runtime amount rounds to by a rule, if it is in the
    /// steps' currency.
    ///
    /// - Parameters:
    ///   - amount: The amount to select, such as a saved one.
    ///   - steps: The steps to choose among.
    ///   - rule: How to choose between the two steps either side of `amount`.
    /// - Throws: ``MoneyStepsRoundingError/currencyMismatch(_:)`` with the currency of `amount` if
    ///   it differs from the steps'; otherwise ``MoneyStepsRoundingError/outOfBounds`` if no step
    ///   satisfies `rule`.
    @inlinable
    init(
        approximating amount: Money,
        in steps: Money.Steps,
        rounding rule: RoundingRule
    ) throws(MoneyStepsRoundingError<AnyCurrency>) {
        self.init(unchecked: steps, index: try steps.index(approximating: amount, rounding: rule))
    }

    /// Returns the selection of the step nearest a runtime amount, in the same steps.
    ///
    /// - Parameter amount: The amount to select.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the steps' currency as `lhs`.
    @inlinable
    func selecting(approximating amount: Money) throws(MoneyError) -> Self {
        try Self(approximating: amount, in: steps)
    }

    /// Returns the selection of the step a runtime amount rounds to by a rule, in the same steps.
    ///
    /// - Parameters:
    ///   - amount: The amount to select.
    ///   - rule: How to choose between the two steps either side of `amount`.
    /// - Throws: ``MoneyStepsRoundingError/currencyMismatch(_:)`` with the currency of `amount` if
    ///   it differs from the steps'; otherwise ``MoneyStepsRoundingError/outOfBounds`` if no step
    ///   satisfies `rule`.
    @inlinable
    func selecting(
        approximating amount: Money,
        rounding rule: RoundingRule
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
