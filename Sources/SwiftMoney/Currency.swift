import Foundation

public protocol Currency: Equatable, Hashable, Sendable {
    #warning("Replace with `CurrencyCode` typed object")
    static var code: String { get }
    #warning("Replace with typed object such as `MinorUnitRatio`")
    /// The ratio of major units to minor units in the decimalized
    /// currency.
    ///
    /// For example, the US Dollar (USD) has a ratio of 1 dollar
    /// to 100 cents, or 1:100, represented as `100`.
    ///
    /// Currencies with no minor units, such as Japanese Yen (JPY),
    /// must have a ratio of `1`.
    ///
    /// A ratio of `0` is not allowed and will cause runtime crashes.
    static var minorUnitRatio: Int64 {  get }
}

public enum EUR: Currency {
    public static let code: String = "EUR"
    public static let minorUnitRatio: Int64 = 100
}

public enum GBP: Currency {
    public static let code: String = "GBP"
    public static let minorUnitRatio: Int64 = 100
}

public enum USD: Currency {
    public static let code: String = "USD"
    public static let minorUnitRatio: Int64 = 100
}

public enum JPY: Currency {
    public static let code: String = "JPY"
    public static let minorUnitRatio: Int64 = 1
}

public enum CHF: Currency {
    public static let code: String = "CHF"
    public static let minorUnitRatio: Int64 = 100
}
