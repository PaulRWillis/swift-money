/// An interval of runtime amounts in one currency, from a lower bound up to, but not including, an
/// upper one.
///
/// The runtime counterpart of `Range<GBP>`. ``Money`` is not `Comparable`, because amounts in
/// different currencies have no order, so a range of them checks the currency once, when it is
/// built, and then holds it:
///
/// ```swift
/// let band = try floor..<ceiling            // throws on a mismatch or inverted bounds
/// try band.contains(amount)                 // throws only if `amount` is in another currency
/// ```
///
/// Its bounds are never inverted and always share a currency, so neither can be represented wrongly.
public struct MoneyRange: Equatable, Hashable, Sendable {
    private let _currency: Currency
    private let _minorUnits: Range<Money.MinorUnits>

    /// Creates a range from two bounds that may not be in order or in one currency.
    ///
    /// The shape of the standard library's `init(uncheckedBounds:)`, but checked: a pair from a
    /// server that arrives swapped, or in two currencies, is caught here rather than trapping.
    ///
    /// ```swift
    /// let band = try MoneyRange(checkedBounds: (lower: floor, upper: ceiling))
    /// ```
    ///
    /// - Parameter bounds: The lower and upper bounds, lowest first.
    /// - Throws: ``CurrencyCheckedError/currencyMismatch(lhs:rhs:)`` if the bounds are in different
    ///   currencies, with the lower bound's as `lhs`; otherwise ``CurrencyCheckedError/failure(_:)``
    ///   with both bounds if the lower is above the upper.
    public init(
        checkedBounds bounds: (lower: Money, upper: Money)
    ) throws(CurrencyCheckedError<InvertedBoundsError<AnyCurrency>>) {
        let currency = bounds.lower.storage
        guard currency == bounds.upper.storage else {
            throw .currencyMismatch(lhs: currency, rhs: bounds.upper.storage)
        }
        guard bounds.lower.minorUnits <= bounds.upper.minorUnits else {
            throw .failure(InvertedBoundsError(lowerBound: bounds.lower, upperBound: bounds.upper))
        }

        self.init(unchecked: currency, minorUnits: bounds.lower.minorUnits ..< bounds.upper.minorUnits)
    }

    /// Creates a runtime range from a typed one, keeping its bounds and currency.
    ///
    /// - Parameter typed: The range whose currency is fixed by its bounds' type.
    @inlinable
    public init<C: CurrencyType>(_ typed: Range<MoneyOf<C>>) {
        self.init(unchecked: C.currency, minorUnits: typed.lowerBound.minorUnits ..< typed.upperBound.minorUnits)
    }

    /// Creates a half-open range holding the same amounts as a closed one, if its upper bound has room
    /// above it.
    ///
    /// The upper bound moves up by one minor unit, the gap between neighboring amounts. Where the
    /// standard library traps when that step overflows, this is `nil`.
    ///
    /// - Parameter range: The closed range to convert.
    /// - Returns: `nil` if `range`'s upper bound is the largest representable amount.
    public init?(_ range: ClosedMoneyRange) {
        let (upper, overflow) = range.upperBound.minorUnits.addingReportingOverflow(1)
        guard !overflow else {
            return nil
        }

        self.init(unchecked: range.currency, minorUnits: range.lowerBound.minorUnits ..< upper)
    }

    // No check: for call sites that already hold ordered bounds in one currency.
    @usableFromInline
    init(
        unchecked currency: Currency,
        minorUnits: Range<Money.MinorUnits>
    ) {
        _currency = currency
        _minorUnits = minorUnits
    }

    /// The currency both bounds, and every amount in the range, are denominated in.
    public var currency: Currency {
        _currency
    }

    /// The range's lower bound, which the range contains unless it is empty.
    public var lowerBound: Money {
        Money(unchecked: _minorUnits.lowerBound, storage: _currency)
    }

    /// The range's upper bound, which the range never contains.
    public var upperBound: Money {
        Money(unchecked: _minorUnits.upperBound, storage: _currency)
    }

    /// Whether the range contains no amounts, which is when its bounds are equal.
    public var isEmpty: Bool {
        _minorUnits.isEmpty
    }

    /// Returns whether an amount lies within the range: at or above the lower bound, below the upper.
    ///
    /// - Parameter amount: The amount to look for.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the range's currency as `lhs`.
    public func contains(_ amount: Money) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, amount.storage)

        return _minorUnits.contains(amount.minorUnits)
    }

    /// Returns whether every amount in another half-open range also lies within this one.
    ///
    /// An empty range holds no amounts, so any range in its currency contains it.
    ///
    /// - Parameter other: The range to look for.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `other` is in another currency, with
    ///   this range's currency as `lhs`.
    public func contains(_ other: MoneyRange) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, other._currency)

        return _minorUnits.contains(other._minorUnits)
    }

    /// Returns whether every amount in a closed range also lies within this one.
    ///
    /// - Parameter other: The range to look for.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `other` is in another currency, with
    ///   this range's currency as `lhs`.
    public func contains(_ other: ClosedMoneyRange) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, other.currency)

        return _minorUnits.contains(other.lowerBound.minorUnits ... other.upperBound.minorUnits)
    }

    /// Returns whether this range and another half-open range share at least one amount.
    ///
    /// An empty range shares no amount with any range.
    ///
    /// - Parameter other: The range to compare with.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `other` is in another currency, with
    ///   this range's currency as `lhs`.
    public func overlaps(_ other: MoneyRange) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, other._currency)

        return _minorUnits.overlaps(other._minorUnits)
    }

    /// Returns whether this range and a closed range share at least one amount.
    ///
    /// - Parameter other: The range to compare with.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `other` is in another currency, with
    ///   this range's currency as `lhs`.
    public func overlaps(_ other: ClosedMoneyRange) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, other.currency)

        return _minorUnits.overlaps(other.lowerBound.minorUnits ... other.upperBound.minorUnits)
    }

    /// Returns this range narrowed to lie within the given limits.
    ///
    /// A range entirely outside the limits collapses to an empty range at the nearer limit, as the
    /// standard library's does.
    ///
    /// - Parameter limits: The range to clamp to.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `limits` is in another currency, with
    ///   this range's currency as `lhs`.
    public func clamped(to limits: MoneyRange) throws(MoneyError) -> MoneyRange {
        try AnyCurrency.requireMatch(_currency, limits._currency)

        return MoneyRange(unchecked: _currency, minorUnits: _minorUnits.clamped(to: limits._minorUnits))
    }
}

extension MoneyRange: CustomStringConvertible {
    /// The range written as the standard library writes a half-open range, with each bound as an
    /// amount.
    ///
    /// ```swift
    /// String(describing: try floor..<ceiling)   // "GBP 10.00..<GBP 250.00"
    /// ```
    public var description: String {
        lowerBound.description + "..<" + upperBound.description
    }
}

extension MoneyRange: CustomDebugStringConvertible {
    /// The range's description, wrapped in its type's name.
    ///
    /// ```swift
    /// String(reflecting: try floor..<ceiling)   // "MoneyRange(GBP 10.00..<GBP 250.00)"
    /// ```
    public var debugDescription: String {
        "MoneyRange(" + description + ")"
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns the half-open range between two runtime amounts, checking their currency and order.
    ///
    /// Bounds usually come from a server or an account's state, so where the standard library's `..<`
    /// traps on inverted bounds, this throws:
    ///
    /// ```swift
    /// let band = try floor..<ceiling
    /// ```
    ///
    /// - Parameters:
    ///   - minimum: The lower bound.
    ///   - maximum: The upper bound, which the range does not contain.
    /// - Throws: ``CurrencyCheckedError/currencyMismatch(lhs:rhs:)`` if the bounds are in different
    ///   currencies; otherwise ``CurrencyCheckedError/failure(_:)`` if `minimum` is above `maximum`.
    @inlinable
    static func ..< (
        minimum: Money,
        maximum: Money
    ) throws(CurrencyCheckedError<InvertedBoundsError<AnyCurrency>>) -> MoneyRange {
        try MoneyRange(checkedBounds: (lower: minimum, upper: maximum))
    }
}
