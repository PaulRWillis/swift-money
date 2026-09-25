import SwiftMoneyCore

extension Gen where Value == Currency {
    /// A generator of ISO 4217 currencies, spanning a scale of none (yen) and of two places (sterling,
    /// euro, dollar), for the runtime-currency and round-trip suites.
    static var isoCurrency: Gen<Currency> {
        Gen.element(of: [.gbp, .eur, .usd, .jpy])
    }

    /// A generator of currencies the library does not ship, at a spread of scales, for the custom-scale
    /// round-trip.
    ///
    /// Each is built once through `customCurrency`, which fails only for a shipped code at another scale;
    /// none of these codes is shipped, so construction always succeeds.
    static var customScaleCurrency: Gen<Currency> {
        Gen.element(of: [
            customCurrency(code: "KHO", unitScale: 1),
            customCurrency(code: "KHO", unitScale: 100),
            customCurrency(code: "PTS", unitScale: 1_000),
            customCurrency(code: "GEM", unitScale: 100_000_000),
        ])
    }
}
