/// A value-type registry that maps ``CurrencyCode`` values to their
/// ``MinimalQuantisation``.
///
/// Use ``isoStandard`` for a pre-populated registry containing all
/// active ISO 4217 currencies, or build a custom registry with
/// ``register(_:)`` and ``register(code:minimalQuantisation:)``.
///
/// ```swift
/// let registry = CurrencyRegistry.isoStandard
/// registry.minimalQuantisation(for: "GBP")   // 100
/// registry.minimalQuantisation(for: "JPY")   // 1
/// ```
///
/// To use with ``AnyMoneyDecodingStrategy`` or
/// ``MoneyBagDecodingStrategy``, call ``asResolver()``:
///
/// ```swift
/// decoder.anyMoneyDecodingStrategy = .object(
///     amount: .majorUnits,
///     resolver: CurrencyRegistry.isoStandard.asResolver()
/// )
/// ```
public struct CurrencyRegistry: Sendable, Equatable, Hashable {

    private var _entries: [CurrencyCode: MinimalQuantisation]

    // MARK: - Initialisation

    /// Creates an empty registry.
    public init() {
        _entries = [:]
    }

    private init(entries: [CurrencyCode: MinimalQuantisation]) {
        _entries = entries
    }

    // MARK: - Registration

    /// Registers a ``Currency`` type by extracting its code and
    /// minimal quantisation.
    ///
    /// If the code is already registered, its quantisation is
    /// overwritten silently.
    public mutating func register<C: Currency>(_ currency: C.Type) {
        _entries[C.code] = C.minimalQuantisation
    }

    /// Registers a currency code with the given minimal quantisation.
    ///
    /// Use this variant for currencies not modelled as static
    /// ``Currency`` types — for example, currencies discovered at
    /// runtime from a server response.
    ///
    /// If the code is already registered, its quantisation is
    /// overwritten silently.
    public mutating func register(
        code: CurrencyCode,
        minimalQuantisation: MinimalQuantisation
    ) {
        _entries[code] = minimalQuantisation
    }

    // MARK: - Lookup

    /// Returns the minimal quantisation for the given currency code,
    /// or `nil` if the code is not registered.
    public func minimalQuantisation(for code: CurrencyCode) -> MinimalQuantisation? {
        _entries[code]
    }

    /// The number of registered currency entries.
    public var count: Int {
        _entries.count
    }

    // MARK: - Resolver

    /// Returns a `@Sendable` closure suitable for use as a resolver
    /// in ``AnyMoneyDecodingStrategy`` and
    /// ``MoneyBagDecodingStrategy``.
    ///
    /// The closure captures a snapshot of the registry at the time of
    /// the call. Subsequent mutations to the registry do not affect
    /// the returned closure.
    public func asResolver() -> @Sendable (CurrencyCode) -> MinimalQuantisation? {
        let snapshot = _entries
        return { code in snapshot[code] }
    }

    // MARK: - ISO 4217 Standard Registry

    /// A registry pre-populated with all active ISO 4217 national
    /// and supranational currencies as of 1 January 2026.
    ///
    /// Does not include fund codes, precious metals, bond market
    /// units, SDR, testing codes, or "no currency" (XXX).
    public static let isoStandard = CurrencyRegistry(
        entries: Dictionary(
            uniqueKeysWithValues: allISOCurrencies.map { ($0.code, $0.minimalQuantisation) }
        )
    )
}
