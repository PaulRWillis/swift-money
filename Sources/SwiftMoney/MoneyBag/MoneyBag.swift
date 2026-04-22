/// A multi-currency money accumulator.
///
/// `MoneyBag` accumulates `Money<C>` values across any number of currencies,
/// deferring currency conversion until an exchange-rate infrastructure is
/// available. This follows Fowler's MoneyBag pattern from *Patterns of
/// Enterprise Application Architecture*.
///
/// ```swift
/// var bag = MoneyBag()
/// bag.add(Money<GBP>(minorUnits: 500))   // £5.00
/// bag.add(Money<EUR>(minorUnits: 1000))  // €10.00
/// bag.add(Money<GBP>(minorUnits: 200))   // adds to existing GBP
///
/// bag.amount(in: GBP.self)  // Money<GBP>(minorUnits: 700)
/// bag.breakdown             // [AnyMoney(EUR, 1000), AnyMoney(GBP, 700)]
/// ```
///
/// For functional construction, use the non-mutating ``adding(_:)`` and
/// ``subtracting(_:)`` methods:
///
/// ```swift
/// let bag = MoneyBag()
///     .adding(gbpPayment)
///     .adding(eurCharge)
/// ```
///
/// ## Negative entries
///
/// Negative accumulated amounts are valid. `MoneyBag` models signed
/// multi-currency positions, not "available funds". Enforcing non-negative
/// constraints is the responsibility of the calling domain model.
///
/// ## NaN
///
/// Adding or subtracting a NaN `Money<C>` value traps with a precondition
/// failure, consistent with `Money<C>` arithmetic.
///
/// ## Future FX support
///
/// A `total(in:using:)` method converting all accumulated amounts to a
/// single currency via an exchange-rate provider will be added when the
/// `ExchangeRateProvider` infrastructure is implemented.
public struct MoneyBag: Sendable {

    // MARK: - Storage

    /// Currency code → accumulated `AnyMoney` for that currency.
    internal var _storage: [CurrencyCode: AnyMoney]

    // MARK: - Initializers

    /// Creates an empty `MoneyBag`.
    public init() {
        self._storage = [:]
    }

    /// Creates a `MoneyBag` pre-populated with a single typed value.
    ///
    /// ```swift
    /// let bag = MoneyBag(Money<GBP>(minorUnits: 500))
    /// ```
    ///
    /// - Parameter money: The initial money value.
    /// - Precondition: `money` must not be NaN.
    public init<C: Currency>(_ money: Money<C>) {
        self._storage = [:]
        add(money)
    }

    // MARK: - Queries

    /// A Boolean value indicating whether the bag contains no entries.
    ///
    /// `isEmpty` remains `false` if an add and a matching subtract produce a
    /// zero amount for a currency — the entry is retained.
    public var isEmpty: Bool {
        _storage.isEmpty
    }

    /// The set of currency codes for all currencies currently in the bag.
    public var currencyCodes: Set<CurrencyCode> {
        Set(_storage.keys)
    }

    /// Returns `true` if the bag contains an entry for the given currency.
    ///
    /// - Parameter currency: The currency type to check.
    public func contains<C: Currency>(_ currency: C.Type) -> Bool {
        _storage[C.code] != nil
    }

    /// Returns the accumulated amount for the given currency, or `nil` if
    /// the currency has not been added.
    ///
    /// ```swift
    /// bag.amount(in: GBP.self)  // Money<GBP>(minorUnits: 700)
    /// bag.amount(in: USD.self)  // nil
    /// ```
    ///
    /// - Parameter currency: The currency type to query.
    /// - Returns: A typed `Money<C>` if the currency is present, else `nil`.
    public func amount<C: Currency>(in currency: C.Type) -> Money<C>? {
        _storage[C.code].flatMap { $0.asMoney(C.self) }
    }

    /// A snapshot of all accumulated amounts, sorted by currency code.
    ///
    /// Entries are `AnyMoney` values carrying `minorUnits`, `currencyCode`,
    /// and `minorUnitRatio`. Zero entries are retained; the bag must be
    /// explicitly cleared to remove them.
    public var breakdown: [AnyMoney] {
        _storage.values.sorted()
    }

    // MARK: - Mutating arithmetic

    /// Adds a typed money value to the bag.
    ///
    /// If the currency is already present, `money` is accumulated into the
    /// existing total. Otherwise a new entry is created.
    ///
    /// ```swift
    /// var bag = MoneyBag()
    /// bag.add(Money<GBP>(minorUnits: 500))
    /// bag.add(Money<GBP>(minorUnits: 200))
    /// bag.amount(in: GBP.self)  // Money<GBP>(minorUnits: 700)
    /// ```
    ///
    /// - Parameter money: The value to add.
    /// - Precondition: `money` must not be NaN.
    /// - Precondition: The accumulated result must not overflow `Int64`.
    public mutating func add<C: Currency>(_ money: Money<C>) {
        precondition(!money.isNaN, "NaN in MoneyBag.add")
        let existing = _storage[C.code]?.minorUnits ?? 0
        let (result, overflow) = existing.addingReportingOverflow(money.minorUnits)
        precondition(!overflow, "MoneyBag.add overflow")
        _storage[C.code] = AnyMoney(
            minorUnits: result,
            currencyCode: C.code,
            minimalQuantisation: C.minimalQuantisation
        )
    }

    /// Subtracts a typed money value from the bag.
    ///
    /// If the currency is already present, `money` is subtracted from the
    /// existing total. Otherwise a new entry is created with a negative amount.
    /// Negative entries are valid — they represent a net negative position.
    ///
    /// ```swift
    /// var bag = MoneyBag()
    /// bag.subtract(Money<GBP>(minorUnits: 100))
    /// bag.amount(in: GBP.self)  // Money<GBP>(minorUnits: -100)
    /// ```
    ///
    /// - Parameter money: The value to subtract.
    /// - Precondition: `money` must not be NaN.
    /// - Precondition: The accumulated result must not overflow `Int64`.
    public mutating func subtract<C: Currency>(_ money: Money<C>) {
        precondition(!money.isNaN, "NaN in MoneyBag.subtract")
        let existing = _storage[C.code]?.minorUnits ?? 0
        let (result, overflow) = existing.subtractingReportingOverflow(money.minorUnits)
        precondition(!overflow, "MoneyBag.subtract overflow")
        _storage[C.code] = AnyMoney(
            minorUnits: result,
            currencyCode: C.code,
            minimalQuantisation: C.minimalQuantisation
        )
    }

    // MARK: - Non-mutating arithmetic

    /// Returns a new `MoneyBag` with the given value added.
    ///
    /// ```swift
    /// let bag = MoneyBag()
    ///     .adding(Money<GBP>(minorUnits: 500))
    ///     .adding(Money<EUR>(minorUnits: 1000))
    /// ```
    ///
    /// - Parameter money: The value to add.
    /// - Returns: A new `MoneyBag` with `money` accumulated.
    /// - Precondition: `money` must not be NaN.
    public func adding<C: Currency>(_ money: Money<C>) -> MoneyBag {
        var copy = self
        copy.add(money)
        return copy
    }

    /// Returns a new `MoneyBag` with the given value subtracted.
    ///
    /// ```swift
    /// let bag = MoneyBag()
    ///     .adding(Money<GBP>(minorUnits: 500))
    ///     .subtracting(Money<GBP>(minorUnits: 200))
    /// // bag.amount(in: GBP.self) == Money<GBP>(minorUnits: 300)
    /// ```
    ///
    /// - Parameter money: The value to subtract.
    /// - Returns: A new `MoneyBag` with `money` subtracted.
    /// - Precondition: `money` must not be NaN.
    public func subtracting<C: Currency>(_ money: Money<C>) -> MoneyBag {
        var copy = self
        copy.subtract(money)
        return copy
    }
}

// MARK: - += / -=

/// Adds a typed money value to the bag in place.
///
/// ```swift
/// var bag = MoneyBag()
/// bag += Money<GBP>(minorUnits: 500)
/// ```
public func += <C: Currency>(lhs: inout MoneyBag, rhs: Money<C>) {
    lhs.add(rhs)
}

/// Subtracts a typed money value from the bag in place.
///
/// ```swift
/// var bag = MoneyBag()
/// bag -= Money<GBP>(minorUnits: 200)
/// ```
public func -= <C: Currency>(lhs: inout MoneyBag, rhs: Money<C>) {
    lhs.subtract(rhs)
}
