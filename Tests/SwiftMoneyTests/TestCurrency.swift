import SwiftMoney

/// A test currency that emulates currencies with
/// 100 minor units to 1 major unit, such as USD and
/// GBP.
enum TST_100: Currency {
    static let code: String = "TST_100"
    static let minorUnitRatio: Int64 = 100
}

/// A test currency that represents an illegal state
/// where `minorUnitRatio` is `0`.
///
/// This is not permitted as the ratio must be a
/// non-zero Integer value.
enum TST_0: Currency {
    static let code: String = "TST_0"
    static let minorUnitRatio: Int64 = 0
}
