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

    /// A registry pre-populated with all active ISO 4217 currencies
    /// as of 1 January 2026.
    ///
    /// Contains national currencies, supranational currencies
    /// (e.g. XAF, XCD, XOF, XPF), and fund codes (e.g. BOV, CLF,
    /// USN, UYW). Does not include precious metals, bond market
    /// units, SDR, testing codes, or "no currency" (XXX).
    public static let isoStandard = CurrencyRegistry(entries: buildISOEntries())
}

// MARK: - ISO 4217 Data

private func buildISOEntries() -> [CurrencyCode: MinimalQuantisation] {
    // Minor unit 0 → minimalQuantisation = 1
    let zeroDecimal: [(String, Int64)] = [
        ("BIF", 1), ("CLP", 1), ("DJF", 1), ("GNF", 1),
        ("ISK", 1), ("JPY", 1), ("KMF", 1), ("KRW", 1),
        ("PYG", 1), ("RWF", 1), ("UGX", 1), ("UYI", 1),
        ("VND", 1), ("VUV", 1), ("XAF", 1), ("XOF", 1),
        ("XPF", 1),
    ]

    // Minor unit 2 → minimalQuantisation = 100
    let twoDecimal: [(String, Int64)] = [
        ("AED", 100), ("AFN", 100), ("ALL", 100), ("AMD", 100),
        ("AOA", 100), ("ARS", 100), ("AUD", 100), ("AWG", 100),
        ("AZN", 100), ("BAM", 100), ("BBD", 100), ("BDT", 100),
        ("BGN", 100), ("BMD", 100), ("BND", 100), ("BOB", 100),
        ("BOV", 100), ("BRL", 100), ("BSD", 100), ("BTN", 100),
        ("BWP", 100), ("BYN", 100), ("BZD", 100), ("CAD", 100),
        ("CDF", 100), ("CHE", 100), ("CHF", 100), ("CHW", 100),
        ("CNY", 100), ("COP", 100), ("COU", 100), ("CRC", 100),
        ("CUP", 100), ("CVE", 100), ("CZK", 100), ("DKK", 100),
        ("DOP", 100), ("DZD", 100), ("EGP", 100), ("ERN", 100),
        ("ETB", 100), ("EUR", 100), ("FJD", 100), ("FKP", 100),
        ("GBP", 100), ("GEL", 100), ("GHS", 100), ("GIP", 100),
        ("GMD", 100), ("GTQ", 100), ("GYD", 100), ("HKD", 100),
        ("HNL", 100), ("HTG", 100), ("HUF", 100), ("IDR", 100),
        ("ILS", 100), ("INR", 100), ("IRR", 100), ("JMD", 100),
        ("KES", 100), ("KGS", 100), ("KHR", 100), ("KPW", 100),
        ("KYD", 100), ("KZT", 100), ("LAK", 100), ("LBP", 100),
        ("LKR", 100), ("LRD", 100), ("LSL", 100), ("MAD", 100),
        ("MDL", 100), ("MGA", 100), ("MKD", 100), ("MMK", 100),
        ("MNT", 100), ("MOP", 100), ("MRU", 100), ("MUR", 100),
        ("MVR", 100), ("MWK", 100), ("MXN", 100), ("MXV", 100),
        ("MYR", 100), ("MZN", 100), ("NAD", 100), ("NGN", 100),
        ("NIO", 100), ("NOK", 100), ("NPR", 100), ("NZD", 100),
        ("PAB", 100), ("PEN", 100), ("PGK", 100), ("PHP", 100),
        ("PKR", 100), ("PLN", 100), ("QAR", 100), ("RON", 100),
        ("RSD", 100), ("RUB", 100), ("SAR", 100), ("SBD", 100),
        ("SCR", 100), ("SDG", 100), ("SEK", 100), ("SGD", 100),
        ("SHP", 100), ("SLE", 100), ("SOS", 100), ("SRD", 100),
        ("SSP", 100), ("STN", 100), ("SVC", 100), ("SYP", 100),
        ("SZL", 100), ("THB", 100), ("TJS", 100), ("TMT", 100),
        ("TOP", 100), ("TRY", 100), ("TTD", 100), ("TWD", 100),
        ("TZS", 100), ("UAH", 100), ("USD", 100), ("USN", 100),
        ("UYU", 100), ("UZS", 100), ("VED", 100), ("VES", 100),
        ("WST", 100), ("XAD", 100), ("XCD", 100), ("XCG", 100),
        ("YER", 100), ("ZAR", 100), ("ZMW", 100), ("ZWG", 100),
    ]

    // Minor unit 3 → minimalQuantisation = 1000
    let threeDecimal: [(String, Int64)] = [
        ("BHD", 1000), ("IQD", 1000), ("JOD", 1000), ("KWD", 1000),
        ("LYD", 1000), ("OMR", 1000), ("TND", 1000),
    ]

    // Minor unit 4 → minimalQuantisation = 10000
    let fourDecimal: [(String, Int64)] = [
        ("CLF", 10000), ("UYW", 10000),
    ]

    let allEntries = zeroDecimal + twoDecimal + threeDecimal + fourDecimal
    var dict = [CurrencyCode: MinimalQuantisation](minimumCapacity: allEntries.count)
    for (code, quantisation) in allEntries {
        dict[CurrencyCode(code)] = MinimalQuantisation(quantisation)
    }
    return dict
}
