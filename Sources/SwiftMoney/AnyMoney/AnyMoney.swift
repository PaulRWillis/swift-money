/// A type-erased money value.
///
/// `AnyMoney` boxes any `Money<C>` into a runtime-currency-tagged value,
/// enabling heterogeneous collections such as `[AnyMoney]` while preserving
/// all compile-time safety on `Money<C>` itself.
///
/// Use ``Money/erased`` to create an `AnyMoney` from a typed value:
///
/// ```swift
/// let arr: [AnyMoney] = [
///     Money<GBP>(minorUnits: 500).erased,
///     Money<EUR>(minorUnits: 1000).erased,
/// ]
/// ```
///
/// Use ``asMoney(_:)`` to recover a typed value when the currency is known:
///
/// ```swift
/// let gbpAmounts = arr.compactMap { $0.asMoney(GBP.self) }
/// let total: Money<GBP> = gbpAmounts.reduce(.zero, +)
/// ```
///
/// `AnyMoney` is a minimal identity token. Arithmetic should be performed on
/// typed `Money<C>` values. See ``asMoney(_:)`` to convert back before
/// computing.
///
/// - Note: There is no `AnyMoney.nan` factory. Use `Money<C>.nan.erased` to
///   obtain a NaN `AnyMoney` for a specific currency.
public struct AnyMoney: Sendable {

    // MARK: - Stored properties

    /// The raw minor units of this money value.
    ///
    /// Uses `Int64.min` as the NaN sentinel, matching `Money<C>` semantics.
    public let minorUnits: Int64

    /// The ISO 4217 or custom currency code, e.g. `CurrencyCode("GBP")`.
    public let currencyCode: CurrencyCode

    /// The number of minimal units per major unit for this currency, e.g. `100`
    /// for GBP (100 pence per pound) or `1` for JPY (no minor units).
    public let minimalQuantisation: MinimalQuantisation

    /// The concrete currency metatype, if known.
    ///
    /// Set when this value is created via ``init(_:)`` from a typed `Money<C>`.
    /// `nil` when decoded from `Codable` (only the scalars are persisted).
    public let currency: (any Currency.Type)?

    // MARK: - Initializers

    /// Creates an `AnyMoney` by erasing the currency type from a typed `Money`.
    ///
    /// ```swift
    /// let typed = Money<GBP>(minorUnits: 500)
    /// let any = AnyMoney(typed)
    /// // or equivalently:
    /// let any = typed.erased
    /// ```
    ///
    /// - Parameter money: The typed money value to erase.
    public init<C: Currency>(_ money: Money<C>) {
        self.minorUnits = money.minorUnits
        self.currencyCode = C.code
        self.minimalQuantisation = C.minimalQuantisation
        self.currency = C.self
    }

    /// Creates an `AnyMoney` from raw scalars, with an optional currency metatype.
    ///
    /// Pass `currency: C.self` when the concrete type is known (e.g. in
    /// `MoneyBag.add`). Omit it (defaulting to `nil`) for `Codable` decoding
    /// where only the scalar fields are available.
    internal init(
        minorUnits: Int64,
        currencyCode: CurrencyCode,
        minimalQuantisation: MinimalQuantisation,
        currency: (any Currency.Type)? = nil
    ) {
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
        self.minimalQuantisation = minimalQuantisation
        self.currency = currency
    }

    // MARK: - Special value queries

    /// A Boolean value indicating whether this value is NaN (not-a-number).
    ///
    /// `true` when ``minorUnits`` equals `Int64.min`, matching `Money<C>` NaN
    /// sentinel semantics.
    @inlinable
    public var isNaN: Bool {
        minorUnits == Int64.min
    }

    /// A Boolean value indicating whether this value is finite (not NaN).
    ///
    /// `AnyMoney` has no infinity representation, so all non-NaN values are
    /// finite.
    @inlinable
    public var isFinite: Bool {
        !isNaN
    }
}
