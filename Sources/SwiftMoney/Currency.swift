import Foundation

public protocol Currency: Equatable, Hashable, Sendable {
    static var code: String { get }
}

public enum EUR: Currency {
    public static let code: String = "EUR"
}

public enum GBP: Currency {
    public static let code: String = "GBP"
}

public enum USD: Currency {
    public static let code: String = "USD"
}
