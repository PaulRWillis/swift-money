public protocol Currency: Equatable, Hashable, Sendable {
    /// The currency code, e.g. `CurrencyCode("GBP")`.
    ///
    /// Because `code` is a `CurrencyCode` (not a raw `String`), the type system
    /// guarantees it is non-empty at the point of declaration.
    static var code: CurrencyCode { get }

    /// The number of minimal units that make one major unit.
    ///
    /// For example:
    /// - GBP → `100`  (100 pence = £1)
    /// - JPY → `1`    (no minor units; ¥1 = ¥1)
    /// - BTC → `100_000_000` (10⁸ satoshis = 1 BTC)
    ///
    /// A value of `0` is rejected by `MinimalQuantisation`, so the type
    /// system prevents the division-by-zero crash that would otherwise
    /// occur in Decimal conversions.
    static var minimalQuantisation: MinimalQuantisation { get }
}
