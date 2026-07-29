/// A currency a monetary amount can be denominated in.
///
/// Exists only as the type parameter of ``MoneyOf``.
///
/// ```swift
/// enum JPY: Currency {
///     static let code = "JPY"
///     static let minimalQuantisation = 1
/// }
/// ```
public protocol Currency: Equatable, Hashable, Sendable {
    /// The currency code, e.g. `GBP`.
    static var code: String { get }

    /// The number of minor units that make one major unit.
    ///
    /// For example:
    /// - GBP → `100`  (100 pence = £1)
    /// - JPY → `1`    (no minor units; ¥1 = ¥1)
    /// - BTC → `100_000_000` (10⁸ satoshis = 1 BTC)
    static var minimalQuantisation: Int { get }
}

/// A namespace for currencies.
public enum Currencies {
    /// The euro.
    public enum EUR: Currency {
        public static let code: String = "EUR"
        public static let minimalQuantisation: Int = 100
    }

    /// Pound sterling.
    public enum GBP: Currency {
        public static let code: String = "GBP"
        public static let minimalQuantisation: Int = 100
    }
}

/// A monetary amount in pounds sterling.
///
/// Distinct from ``Currencies/GBP``, which is the currency rather than an amount in it.
public typealias GBP = MoneyOf<Currencies.GBP>

/// A monetary amount in euros.
///
/// Distinct from ``Currencies/EUR``, which is the currency rather than an amount in it.
public typealias EUR = MoneyOf<Currencies.EUR>
