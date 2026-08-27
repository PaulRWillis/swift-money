import SwiftMoney

// Builds a currency the library does not ship, for tests that need a custom code and scale.
//
// `Currency(code:unitScale:)` is failable because a shipped code at the wrong scale is rejected. A
// test code such as "KHO" or "BTC" is never a shipped one, so the value always exists; this unwraps
// it once, with a message, rather than repeating a guard at every definition. It is only for
// definitely-valid custom currencies, never for validating input.
func customCurrency(code: CurrencyCode, unitScale: UnitScale) -> Currency {
    guard let currency = Currency(code: code, unitScale: unitScale) else {
        preconditionFailure("\(code) must not be a currency the library ships at another scale")
    }

    return currency
}
