public protocol Currency: Equatable, Hashable, Sendable {
    /// The currency code, e.g. `CurrencyCode("GBP")`.
    static var code: CurrencyCode { get }

    /// The number of minimal units that make one major unit.
    ///
    /// For example:
    /// - GBP → `100`  (100 pence = £1)
    /// - JPY → `1`    (no minor units; ¥1 = ¥1)
    /// - BTC → `100_000_000` (10⁸ satoshis = 1 BTC)
    static var minimalQuantisation: MinimalQuantisation { get }
}
