import SwiftMoney

/// A test currency that represents an illegal state
/// where `minorUnitRatio` is `0`.
///
/// This is not permitted as the ratio must be a
/// non-zero Integer value.
enum TST_0: Currency {
    static let code: String = "TST_0"
    static let minorUnitRatio: Int64 = 0
}

/// A test currency that emulates currencies with
/// no minor units, such as JPY.
enum TST_1: Currency {
    static let code: String = "TST_1"
    static let minorUnitRatio: Int64 = 1
}

/// A test currency that emulates currencies with
/// 100 minor units to 1 major unit, such as USD and
/// GBP.
enum TST_100: Currency {
    static let code: String = "TST_100"
    static let minorUnitRatio: Int64 = 100
}

/// A test currency that emulates currencies with
/// 100,000,000 minor units to 1 major unit, such as bitcoin
/// (BTC).
enum TST_100_000_000: Currency {
    static let code: String = "TST_100_000_000"
    static let minorUnitRatio: Int64 = 100_000_000
}
