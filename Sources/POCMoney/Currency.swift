public protocol Currency: Equatable, Hashable, Sendable {
    /// The currency code, e.g. `GBP`.
    static var code: String { get }

    /// The number of minimal units that make one major unit.
    ///
    /// For example:
    /// - GBP → `100`  (100 pence = £1)
    /// - JPY → `1`    (no minor units; ¥1 = ¥1)
    /// - BTC → `100_000_000` (10⁸ satoshis = 1 BTC)
    static var minimalQuantisation: Int { get }
}

public enum Currencies {
    public enum EUR: Currency {
        public static let code: String = "EUR"
        public static let minimalQuantisation: Int = 100
    }

    public enum GBP: Currency {
        public static let code: String = "GBP"
        public static let minimalQuantisation: Int = 100
    }
}
