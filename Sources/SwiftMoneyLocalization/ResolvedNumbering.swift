import SwiftMoneyCore

// How a requested numbering system resolves against a locale's baked format. Decoded once — parse, don't
// validate — so applying it can never combine, say, a system's digits with the wrong separators.
package enum ResolvedNumbering: Equatable {
    // The baked format is used unchanged: no system was requested, or the request is the locale's own
    // default. This is the path that stays byte-identical to before the feature.
    case baked

    // A reuse system: swap the digits, keep the locale's own separators.
    case swapDigits(Digits)

    // An imposing system: use its separators (its default, or a per-locale override) and its digits.
    case systemSymbols(NumberingSystemSymbols, digits: Digits)

    // The format this resolution renders with, built from the locale's baked format.
    package func applied(to baked: LocaleNumberFormat) -> LocaleNumberFormat {
        switch self {
        case .baked:
            baked
        case .swapDigits(let digits):
            baked.replacingDigits(digits)
        case .systemSymbols(let symbols, let digits):
            baked.replacing(symbols: symbols, digits: digits)
        }
    }
}
