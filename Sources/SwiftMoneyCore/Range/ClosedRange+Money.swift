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
    /// - Parameter bounds: The lower and upper bounds, lowest first.
    /// - Throws: ``InvertedBoundsError`` with both bounds if the lower is above the upper.
    @inlinable
    init<C: CurrencyType>(
        checkedBounds bounds: (lower: MoneyOf<C>, upper: MoneyOf<C>)
    ) throws(InvertedBoundsError<C>) where Bound == MoneyOf<C> {
        guard bounds.lower <= bounds.upper else {
            throw InvertedBoundsError(lowerBound: bounds.lower, upperBound: bounds.upper)
        }

        self = bounds.lower ... bounds.upper
    }
}
