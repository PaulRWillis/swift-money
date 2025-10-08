import Foundation

public protocol Currency: Hashable {
    static var code: String { get }
    static var name: String { get }
    static var minorUnit: Int { get }
}

public enum EUR: Currency {
    public static let code: String = "EUR"
    public static let name: String = "Euro"
    public static let minorUnit: Int = 2
}

public enum GBP: Currency {
    public static let code: String = "GBP"
    public static let name: String = "Pound Sterling"
    public static let minorUnit: Int = 2
}

public enum USD: Currency {
    public static let code: String = "USD"
    public static let name: String = "US Dollar"
    public static let minorUnit: Int = 2
}
