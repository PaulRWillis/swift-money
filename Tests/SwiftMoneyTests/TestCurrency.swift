import SwiftMoney

enum TST: Currency {
    static let code: String = "TST"
    static let minorUnits: Int64 = 100
}

enum NO_MINOR_UNITS: Currency {
    static let code: String = "NO_MINOR_UNITS"
    static let minorUnits: Int64 = 0
}
