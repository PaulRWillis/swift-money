import SwiftMoney

/// A test currency that emulates currencies with
/// no minor units, such as JPY.
enum TST_1: Currency {
    static let code: CurrencyCode = "TST_1"
    static let minimalQuantisation: MinimalQuantisation = 1
}

/// A test currency that emulates currencies with
/// 100 minor units to 1 major unit, such as USD and
/// GBP.
enum TST_100: Currency {
    static let code: CurrencyCode = "TST_100"
    static let minimalQuantisation: MinimalQuantisation = 100
}

/// A test currency that emulates currencies with
/// 100,000,000 minor units to 1 major unit, such as bitcoin
/// (BTC).
enum TST_100_000_000: Currency {
    static let code: CurrencyCode = "TST_100_000_000"
    static let minimalQuantisation: MinimalQuantisation = 100_000_000
}
