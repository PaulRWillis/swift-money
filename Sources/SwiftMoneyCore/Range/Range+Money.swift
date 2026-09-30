// Every member here is constrained to typed money bounds, so none of them claims the standard
// library's namespace for other `Comparable` types.
public extension Range {
    /// Creates a half-open range of typed amounts from two bounds that may not be in order.
    ///
    /// The shape of the standard library's `init(uncheckedBounds:)`, but checked: where `..<` traps
    /// on bounds from a server that arrive swapped, this throws. Both bounds share a type, so their
    /// currencies already match and inverted bounds are the only failure.
    ///
    /// ```swift
    /// let band = try Range(checkedBounds: (lower: floor, upper: ceiling))
    /// ```
    ///
    /// - Parameter bounds: The lower and upper bounds, lowest first.
    /// - Throws: ``InvertedBoundsError`` with both bounds if the lower is above the upper.
    @inlinable
    init<C: CurrencyType>(
        checkedBounds bounds: (lower: MoneyOf<C>, upper: MoneyOf<C>)
    ) throws(InvertedBoundsError<C>) where Bound == MoneyOf<C> {
        guard bounds.lower <= bounds.upper else {
            throw InvertedBoundsError(lowerBound: bounds.lower, upperBound: bounds.upper)
        }

        self = bounds.lower ..< bounds.upper
    }

    /// Creates a half-open range of typed amounts from a runtime range, if it is in the bounds'
    /// currency.
    ///
    /// ```swift
    /// let band = try Range<GBP>(runtimeBand)
    /// ```
    ///
    /// - Parameter range: The range whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `range` is in another currency, with
    ///   the bounds' currency as `lhs`.
    @inlinable
    init<C: CurrencyType>(_ range: MoneyRange) throws(MoneyError) where Bound == MoneyOf<C> {
        try AnyCurrency.requireMatch(C.currency, range.currency)

        self = MoneyOf<C>(unchecked: range.lowerBound.minorUnits, storage: .implied)
            ..< MoneyOf<C>(unchecked: range.upperBound.minorUnits, storage: .implied)
    }

    /// Creates a half-open range holding the same amounts as a closed one, if its upper bound has room
    /// above it.
    ///
    /// The upper bound moves up by one minor unit, the gap between neighboring amounts. Where the
    /// standard library traps when that step overflows, this is `nil`.
    ///
    /// - Parameter range: The closed range to convert.
    /// - Returns: `nil` if `range`'s upper bound is the largest representable amount.
    @inlinable
    init?<C: CurrencyType>(_ range: ClosedRange<MoneyOf<C>>) where Bound == MoneyOf<C> {
        let (upper, overflow) = range.upperBound.minorUnits.addingReportingOverflow(1)
        guard !overflow else {
            return nil
        }

        self = range.lowerBound ..< MoneyOf<C>(unchecked: upper, storage: .implied)
    }
}
