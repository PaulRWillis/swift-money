/// An interval of runtime amounts in one currency, from a lower bound up to and including an upper
/// one.
///
/// The runtime counterpart of `ClosedRange<GBP>`. ``Money`` is not `Comparable`, because amounts in
/// different currencies have no order, so a range of them checks the currency once, when it is
/// built, and then holds it:
///
/// ```swift
/// let limits = try minimum...maximum        // throws on a mismatch or inverted bounds
/// try limits.contains(amount)               // throws only if `amount` is in another currency
/// ```
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
    /// - Parameter bounds: The lower and upper bounds, lowest first.
    /// - Throws: ``CurrencyCheckedError/currencyMismatch(lhs:rhs:)`` if the bounds are in different
    ///   currencies, with the lower bound's as `lhs`; otherwise ``CurrencyCheckedError/failure(_:)``
    ///   with both bounds if the lower is above the upper.
    @inlinable
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

        self.init(unchecked: currency, minorUnits: bounds.lower.minorUnits ... bounds.upper.minorUnits)
    }

    /// Creates a runtime range from a typed one, keeping its bounds and currency.
    ///
    /// - Parameter typed: The range whose currency is fixed by its bounds' type.
    @inlinable
    public init<C: CurrencyType>(_ typed: ClosedRange<MoneyOf<C>>) {
        self.init(unchecked: C.currency, minorUnits: typed.lowerBound.minorUnits ... typed.upperBound.minorUnits)
    }

    // No check: for call sites that already hold ordered bounds in one currency.
    @usableFromInline
    init(
        unchecked currency: Currency,
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
        "ClosedMoneyRange(" + description + ")"
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
    /// - Throws: ``CurrencyCheckedError/currencyMismatch(lhs:rhs:)`` if the bounds are in different
    ///   currencies; otherwise ``CurrencyCheckedError/failure(_:)`` if `minimum` is above `maximum`.
    @inlinable
    static func ... (
        minimum: Money,
        maximum: Money
    ) throws(CurrencyCheckedError<InvertedBoundsError<AnyCurrency>>) -> ClosedMoneyRange {
        try ClosedMoneyRange(checkedBounds: (lower: minimum, upper: maximum))
    }
}
