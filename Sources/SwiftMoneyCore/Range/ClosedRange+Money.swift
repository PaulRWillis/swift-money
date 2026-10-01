// Every member here is constrained to typed money bounds, so none of them claims the standard
// library's namespace for other `Comparable` types.
public extension ClosedRange {
    /// Creates a range of typed amounts from two bounds that may not be in order.
    ///
    /// The shape of the standard library's `init(uncheckedBounds:)`, but checked: where `...` traps
    /// on bounds from a server that arrive swapped, this throws. Both bounds share a type, so their
    /// currencies already match and inverted bounds are the only failure.
    ///
    /// ```swift
    /// let limits = try ClosedRange(checkedBounds: (lower: minimum, upper: maximum))
    /// ```
    ///
    /// - Parameter bounds: The lower and upper bounds, the intended lower one first.
    /// - Throws: ``MoneyRangeParsingError/invertedBounds(lowerBound:upperBound:)`` with both bounds
    ///   if the lower is above the upper.
    @inlinable
    init<C: CurrencyType>(
        checkedBounds bounds: (lower: MoneyOf<C>, upper: MoneyOf<C>)
    ) throws(MoneyRangeParsingError<C>) where Bound == MoneyOf<C> {
        guard bounds.lower <= bounds.upper else {
            throw .invertedBounds(lowerBound: bounds.lower, upperBound: bounds.upper)
        }

        self = bounds.lower ... bounds.upper
    }

    /// Creates a range of typed amounts from a runtime range, if it is in the bounds' currency.
    ///
    /// ```swift
    /// let limits = try ClosedRange<GBP>(runtimeLimits)
    /// ```
    ///
    /// - Parameter range: The range whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `range` is in another currency, with
    ///   the bounds' currency as `lhs`.
    @inlinable
    init<C: CurrencyType>(_ range: ClosedMoneyRange) throws(MoneyError) where Bound == MoneyOf<C> {
        try AnyCurrency.requireMatch(C.currency, range.currency)

        self = MoneyOf<C>(unchecked: range.lowerBound.minorUnits, storage: .implied)
            ... MoneyOf<C>(unchecked: range.upperBound.minorUnits, storage: .implied)
    }

    /// Creates a closed range holding the same amounts as a half-open one, if it holds any.
    ///
    /// The upper bound moves down by one minor unit, the gap between neighboring amounts. Where the
    /// standard library traps on an empty range, this is `nil`.
    ///
    /// - Parameter range: The half-open range to convert.
    /// - Returns: `nil` if `range` is empty, since a closed range always holds its bounds.
    @inlinable
    init?<C: CurrencyType>(_ range: Range<MoneyOf<C>>) where Bound == MoneyOf<C> {
        guard !range.isEmpty else {
            return nil
        }

        // Not empty, so the upper bound is above the lower and one minor unit less cannot underflow.
        self = range.lowerBound ... MoneyOf<C>(unchecked: range.upperBound.minorUnits - 1, storage: .implied)
    }

    /// Returns whether every amount in a half-open range also lies within this one.
    ///
    /// An empty range holds no amounts, so any range contains it. `£0...£1` contains `£0..<£1.01`,
    /// whose last amount is £1.00.
    ///
    /// ```swift
    /// let limits = GBP.zero ... GBP(minorUnits: 1_00)
    /// limits.contains(GBP.zero ..< GBP(minorUnits: 1_01))   // true
    /// limits.contains(GBP.zero ..< GBP(minorUnits: 1_02))   // false
    /// ```
    ///
    /// - Parameter other: The range to look for.
    /// - Returns: `true` if `other` is empty or every amount in it lies within this range;
    ///   otherwise, `false`.
    @inlinable
    func contains<C: CurrencyType>(_ other: Range<MoneyOf<C>>) -> Bool where Bound == MoneyOf<C> {
        (lowerBound.minorUnits ... upperBound.minorUnits)
            .contains(other.lowerBound.minorUnits ..< other.upperBound.minorUnits)
    }

    /// Returns every amount in the range, one stride apart, ending exactly on the far bound.
    ///
    /// The stops of a slider. Unlike `stride(from:through:by:)`, the far bound is always a step, even
    /// when no stride lands on it:
    ///
    /// ```swift
    /// try (GBP(minorUnits: 10_00)...GBP(minorUnits: 250_00)).steps(by: .majorUnits(100))
    /// // £10, £110, £210, £250
    /// ```
    ///
    /// A negative stride starts on the upper bound and counts down to the lower.
    ///
    /// - Parameter stride: The gap between neighboring steps. The last gap may be shorter.
    /// - Throws: ``MoneyStepsParsingError/tooManySteps`` if there would be more steps than `Int` can
    ///   count.
    @inlinable
    func steps<C: CurrencyType>(
        by stride: MoneyOf<C>.Stride
    ) throws(MoneyStepsParsingError<C>) -> MoneyOf<C>.Steps where Bound == MoneyOf<C> {
        try MoneyOf<C>.Steps(
            checking: .implied,
            span: lowerBound.minorUnits ... upperBound.minorUnits,
            by: NonZeroInt64(unchecked: stride.amount.minorUnits)
        )
    }
}
