import Foundation
import SwiftMoneyCore

/// The presentation x sign x grouping x separator cross, and the currencies/locales/amounts it is
/// exercised over.
///
/// Shared between `MoneyFormatStyleGoldenTests` (the portable correctness gate, which hashes the
/// engine's own output) and the ICU deviation report (non-gating intelligence, which compares the
/// engine's output to the platform's ICU). One set of inputs, so the two can never silently drift onto
/// different currencies, locales, options or amounts.
package enum FormatMatrix {
    /// The vocabulary `Decimal.FormatStyle.Currency` and `MoneyOf.FormatStyle` share.
    package typealias Config = CurrencyFormatStyleConfiguration

    /// One point of the presentation x sign x grouping x separator cross.
    package struct Combination {
        package let id: String
        package let presentation: Config.Presentation
        package let sign: Config.SignDisplayStrategy
        package let grouping: Config.Grouping
        package let separator: Config.DecimalSeparatorDisplayStrategy

        /// Whether this combination hits Foundation's own known defect: turning grouping off while
        /// a sign or decimal-separator strategy is also set drops the currency symbol entirely,
        /// even though both are genuinely non-default. Locale-, currency- and amount-independent,
        /// so classifying by the combination alone is exact. Pinned directly against
        /// `Decimal.FormatStyle.Currency` by `MoneyFormatStyleModifierTests`.
        package var isKnownFoundationGroupingDefect: Bool {
            grouping != .automatic && (sign != .automatic || separator != .automatic)
        }
    }

    package static let presentations: [(name: String, f: Config.Presentation)] =
        [("standard", .standard), ("isoCode", .isoCode), ("narrow", .narrow)]
    package static let signs: [(name: String, f: Config.SignDisplayStrategy)] =
        [("automatic", .automatic), ("never", .never), ("always", .always()), ("accounting", .accounting)]
    package static let groupings: [(name: String, f: Config.Grouping)] =
        [("automatic", .automatic), ("never", .never)]
    package static let separators: [(name: String, f: Config.DecimalSeparatorDisplayStrategy)] =
        [("automatic", .automatic), ("always", .always)]

    /// The full cross, precomputed once since it is the same for every locale.
    package static let combinations: [Combination] = presentations.flatMap { p in
        signs.flatMap { s in
            groupings.flatMap { g in
                separators.map { d in
                    Combination(
                        id: "\(p.name)|\(s.name)|\(g.name)|\(d.name)",
                        presentation: p.f, sign: s.f, grouping: g.f, separator: d.f
                    )
                }
            }
        }
    }

    /// The locales the CLDR data covers.
    package static let coveredLocaleIDs = ["en_US", "en_GB", "de_DE", "fr_FR", "ja_JP"]

    /// Amounts spanning zero, a typical value, a large value, and a negative value.
    package static let amounts: [Int64] = [0, 1_00, 12_34_56, -12_34_56, 1_234_567_89]

    /// Scale-spanning currencies (0/2/3 decimal places), for exercising the option cross without
    /// repeating it for every currency: that cross is currency-independent engine code.
    package static let optionCurrencies: [Currency] = [.jpy, .gbp, .bhd]
}
