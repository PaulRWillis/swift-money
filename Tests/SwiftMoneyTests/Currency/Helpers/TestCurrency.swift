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

/// A test currency backed by the real ISO 4217 code "KWD"
/// (Kuwaiti Dinar), which has 1000 fils to the dinar.
///
/// Used in localisation tests to exercise 3-decimal-place currencies.
/// Using the real ISO code ensures Foundation's formatter renders a
/// recognisable symbol and the fidelity comparison is meaningful.
enum TestKWD: Currency {
    static let code: CurrencyCode = "KWD"
    static let minimalQuantisation: MinimalQuantisation = 1000
}
