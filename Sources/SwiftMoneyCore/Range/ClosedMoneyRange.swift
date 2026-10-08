/// An interval of runtime amounts in one currency, from a lower bound up to and including an upper
/// one.
///
/// The runtime counterpart of `ClosedRange<GBP>`. ``Money`` is not `Comparable`, because amounts in
/// different currencies have no order, so a range of them checks the currency once, when it is
/// built, and then holds it:
///
/// ```swift
/// let limits = try minimum...maximum        // throws MoneyRangeParsingError
/// try limits.contains(amount)               // throws MoneyError
/// ```
///
/// Building one throws ``MoneyRangeParsingError``. A call on a built range whose only failure is an
/// amount in another currency, such as ``contains(_:)``, throws ``MoneyError``, as arithmetic does.
///
/// Its bounds are never inverted and always share a currency, so neither can be represented wrongly.
public struct ClosedMoneyRange: Equatable, Hashable, Sendable {
    @usableFromInline
    let _currency: Currency

    @usableFromInline
    let _minorUnits: ClosedRange<Money.MinorUnits>

    /// Creates a range from two bounds that may not be in order or in one currency.
    ///
    /// The shape of the standard library's `init(uncheckedBounds:)`, but checked: a pair from a
    /// server that arrives swapped, or in two currencies, is caught here rather than trapping.
    ///
    /// ```swift
    /// let limits = try ClosedMoneyRange(checkedBounds: (lower: minimum, upper: maximum))
    /// ```
    ///
    /// - Parameter bounds: The lower and upper bounds, the intended lower one first.
    /// - Throws: ``MoneyRangeParsingError/currencyMismatch(_:)`` with the upper bound's currency if
    ///   the bounds are in different currencies; otherwise
    ///   ``MoneyRangeParsingError/invertedBounds(lowerBound:upperBound:)`` with both bounds if the
    ///   lower is above the upper.
    @inlinable
    public init(
        checkedBounds bounds: (lower: Money, upper: Money)
    ) throws(MoneyRangeParsingError<AnyCurrency>) {
        let currency = bounds.lower.storage
        guard currency == bounds.upper.storage else {
            throw .currencyMismatch(bounds.upper.currency)
        }
        guard bounds.lower.minorUnits <= bounds.upper.minorUnits else {
            throw .invertedBounds(lowerBound: bounds.lower, upperBound: bounds.upper)
        }

        self.init(currency: currency, minorUnits: bounds.lower.minorUnits ... bounds.upper.minorUnits)
    }

    /// Creates a runtime range from a typed one, keeping its bounds and currency.
    ///
    /// - Parameter typed: The range whose currency is fixed by its bounds' type.
    @inlinable
    public init<C: CurrencyType>(_ typed: ClosedRange<MoneyOf<C>>) {
        self.init(currency: C.currency, minorUnits: typed.lowerBound.minorUnits ... typed.upperBound.minorUnits)
    }

    /// Creates a closed range holding the same amounts as a half-open one, if it holds any.
    ///
    /// The upper bound moves down by one minor unit, the gap between neighboring amounts. Where the
    /// standard library traps on an empty range, this is `nil`.
    ///
    /// - Parameter range: The half-open range to convert.
    /// - Returns: `nil` if `range` is empty, since a closed range always holds its bounds.
    public init?(_ range: MoneyRange) {
        guard !range.isEmpty else {
            return nil
        }

        // Not empty, so the upper bound is above the lower and one minor unit less cannot underflow.
        self.init(
            currency: range.currency,
            minorUnits: range.lowerBound.minorUnits ... range.upperBound.minorUnits - 1
        )
    }

    /// Creates a range of amounts in one currency from a range of minor units.
    ///
    /// - Parameters:
    ///   - currency: The currency of both bounds.
    ///   - minorUnits: The bounds, in minor units of `currency`.
    @usableFromInline
    init(
        currency: Currency,
        minorUnits: ClosedRange<Money.MinorUnits>
    ) {
        _currency = currency
        _minorUnits = minorUnits
    }

    /// The currency both bounds, and every amount in the range, are denominated in.
    public var currency: Currency {
        _currency
    }

    /// The range's lower bound.
    public var lowerBound: Money {
        Money(unchecked: _minorUnits.lowerBound, storage: _currency)
    }

    /// The range's upper bound, which the range contains.
    public var upperBound: Money {
        Money(unchecked: _minorUnits.upperBound, storage: _currency)
    }

    /// Whether the range contains no amounts, which a closed range never does.
    ///
    /// Always `false`, as for the standard library's `ClosedRange`: it contains at least its bounds.
    public var isEmpty: Bool {
        false
    }

    /// Returns whether an amount lies within the range, bounds included.
    ///
    /// - Parameter amount: The amount to look for.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `amount` is in another currency, with
    ///   the range's currency as `lhs`.
    public func contains(_ amount: Money) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, amount.storage)

        return _minorUnits.contains(amount.minorUnits)
    }

    /// Returns whether every amount in another closed range also lies within this one.
    ///
    /// - Parameter other: The range to look for.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `other` is in another currency, with
    ///   this range's currency as `lhs`.
    public func contains(_ other: ClosedMoneyRange) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, other._currency)

        return _minorUnits.contains(other._minorUnits)
    }

    /// Returns whether every amount in a half-open range also lies within this one.
    ///
    /// An empty range holds no amounts, so any range in its currency contains it. `£0...£1` contains
    /// `£0..<£1.01`, whose last amount is £1.00.
    ///
    /// - Parameter other: The range to look for.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `other` is in another currency, with
    ///   this range's currency as `lhs`.
    public func contains(_ other: MoneyRange) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, other.currency)

        return _minorUnits.contains(other.lowerBound.minorUnits ..< other.upperBound.minorUnits)
    }

    /// Returns whether this range and another closed range share at least one amount.
    ///
    /// - Parameter other: The range to compare with.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `other` is in another currency, with
    ///   this range's currency as `lhs`.
    public func overlaps(_ other: ClosedMoneyRange) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, other._currency)

        return _minorUnits.overlaps(other._minorUnits)
    }

    /// Returns whether this range and a half-open range share at least one amount.
    ///
    /// An empty range shares no amount with any range.
    ///
    /// - Parameter other: The range to compare with.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `other` is in another currency, with
    ///   this range's currency as `lhs`.
    public func overlaps(_ other: MoneyRange) throws(MoneyError) -> Bool {
        try AnyCurrency.requireMatch(_currency, other.currency)

        return _minorUnits.overlaps(other.lowerBound.minorUnits ..< other.upperBound.minorUnits)
    }

    /// Returns this range narrowed to lie within the given limits.
    ///
    /// ```swift
    /// let requested = try pounds(5)...pounds(500)
    /// try requested.clamped(to: allowed)   // £10...£250 when `allowed` is £10...£250
    /// ```
    ///
    /// A range entirely outside the limits collapses onto the nearer limit, as the standard library's
    /// does.
    ///
    /// - Parameter limits: The range to clamp to.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `limits` is in another currency, with
    ///   this range's currency as `lhs`.
    public func clamped(to limits: ClosedMoneyRange) throws(MoneyError) -> ClosedMoneyRange {
        try AnyCurrency.requireMatch(_currency, limits._currency)

        return ClosedMoneyRange(currency: _currency, minorUnits: _minorUnits.clamped(to: limits._minorUnits))
    }

    /// Returns every amount in the range, one stride apart, ending exactly on the far bound.
    ///
    /// The stops of a slider. The currency is checked once, here, so using the steps never throws:
    ///
    /// ```swift
    /// let steps = try limits.steps(by: .majorUnit(of: limits.currency))
    /// ```
    ///
    /// A negative stride starts on the upper bound and counts down to the lower.
    ///
    /// - Parameter stride: The gap between neighboring steps. The last gap may be shorter.
    /// - Throws: ``MoneyStepsParsingError/currencyMismatch(_:)`` with the currency of `stride` if it
    ///   differs from the range's; otherwise ``MoneyStepsParsingError/tooManySteps`` if there would
    ///   be more steps than `Int` can count.
    @inlinable
    public func steps(by stride: Money.Stride) throws(MoneyStepsParsingError<AnyCurrency>) -> Money.Steps {
        guard _currency == stride.amount.storage else {
            throw .currencyMismatch(stride.amount.currency)
        }

        return try Money.Steps(storage: _currency, span: _minorUnits, by: stride.minorUnits)
    }
}

extension ClosedMoneyRange: CustomStringConvertible {
    /// The range written as the standard library writes a closed range, with each bound as an amount.
    ///
    /// ```swift
    /// String(describing: try minimum...maximum)   // "GBP 10.00...GBP 250.00"
    /// ```
    public var description: String {
        rangeDescription(lowerBound, "...", upperBound)
    }
}

extension ClosedMoneyRange: CustomDebugStringConvertible {
    /// The range's description, wrapped in its type's name.
    ///
    /// ```swift
    /// String(reflecting: try minimum...maximum)   // "ClosedMoneyRange(GBP 10.00...GBP 250.00)"
    /// ```
    public var debugDescription: String {
        rangeDescription(lowerBound, "...", upperBound, opening: "ClosedMoneyRange(", closing: ")")
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns the closed range between two runtime amounts, checking their currency and order.
    ///
    /// Bounds usually come from a server or an account's state, so where the standard library's `...`
    /// traps on inverted bounds, this throws:
    ///
    /// ```swift
    /// let limits = try minimum...maximum
    /// ```
    ///
    /// - Parameters:
    ///   - minimum: The lower bound.
    ///   - maximum: The upper bound, which the range contains.
    /// - Throws: ``MoneyRangeParsingError/currencyMismatch(_:)`` with the currency of `maximum` if
    ///   the bounds are in different currencies; otherwise
    ///   ``MoneyRangeParsingError/invertedBounds(lowerBound:upperBound:)`` if `minimum` is above
    ///   `maximum`.
    @inlinable
    static func ... (
        minimum: Money,
        maximum: Money
    ) throws(MoneyRangeParsingError<AnyCurrency>) -> ClosedMoneyRange {
        try ClosedMoneyRange(checkedBounds: (lower: minimum, upper: maximum))
    }
}
