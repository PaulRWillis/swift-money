import Foundation

public protocol Currency: Equatable, Hashable, Sendable {
    static var code: String { get }
    static var minorUnits: Int64 {  get }
}

public enum EUR: Currency {
    public static let code: String = "EUR"
    public static let minorUnits: Int64 = 100
}

public enum GBP: Currency {
    public static let code: String = "GBP"
    public static let minorUnits: Int64 = 100
}

public enum USD: Currency {
    public static let code: String = "USD"
    public static let minorUnits: Int64 = 100
}

public enum JPY: Currency {
    public static let code: String = "JPY"
    public static let minorUnits: Int64 = 1
}

public enum CHF: Currency {
    public static let code: String = "CHF"
    public static let minorUnits: Int64 = 100
}
