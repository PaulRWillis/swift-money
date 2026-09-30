import SwiftMoneyCore

// A currency the library does not ship, at a scale of a thousand minor units per major unit, so the
// suites cover a typed currency that is neither two places nor none.
enum Millicredits: CurrencyType {
    static let currency = customCurrency(code: "MCR", unitScale: 1_000)
}
