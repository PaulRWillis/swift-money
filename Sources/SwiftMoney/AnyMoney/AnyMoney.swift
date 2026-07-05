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
/// Use ``Money/init(_:)-anyMoney`` to recover a typed value when the currency is known:
///
/// ```swift
/// let gbpAmounts = arr.compactMap { Money<GBP>.init($0) }
/// let total: Money<GBP> = gbpAmounts.reduce(.zero, +)
/// ```
///
/// `AnyMoney` is a minimal identity token. Arithmetic should be performed on
/// typed `Money<C>` values. See ``Money/init(_:)-anyMoney`` to convert back
/// before computing.
public struct AnyMoney: Sendable {

    #warning("Allow `AnyMoney` to have addition, subtraction, distribution, integral multiplication, and fractional multiplication for systems where the currency is not known at runtime")
    
    // MARK: - Stored properties

    internal typealias Storage = MinorUnit

    /// The raw minor units of this money value, stored as a validated `MinorUnit`.
    private let _minorUnits: Storage

    /// The raw minor units of this money value.
    ///
    /// Represents the value in the currency's smallest denomination.
    public var minorUnits: Int64 { Int64(_minorUnits) }

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
        self._minorUnits = money._storage
        self.currencyCode = C.code
        self.minimalQuantisation = C.minimalQuantisation
        self.currency = C.self
    }

    /// Creates an `AnyMoney` from validated storage, with an optional currency metatype.
    ///
    /// Pass `currency: C.self` when the concrete type is known (e.g. in
    /// `MoneyBag.add`). Omit it (defaulting to `nil`) for `Codable` decoding
    /// where only the scalar fields are available.
    internal init(
        storage: Storage,
        currencyCode: CurrencyCode,
        minimalQuantisation: MinimalQuantisation,
        currency: (any Currency.Type)? = nil
    ) {
        self._minorUnits = storage
        self.currencyCode = currencyCode
        self.minimalQuantisation = minimalQuantisation
        self.currency = currency
    }
}
