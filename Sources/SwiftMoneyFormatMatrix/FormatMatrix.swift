import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization

/// Currency-format inputs (option cross, locales, amounts), so multiple consumers share one set
/// instead of drifting onto different ones.
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

        /// Whether this combination triggers Foundation's known symbol-drop defect: grouping off
        /// with a non-default sign or separator drops the currency symbol.
        package var isKnownFoundationGroupingDefect: Bool {
            grouping != .automatic && (sign != .automatic || separator != .automatic)
        }
    }

    package static let presentations: [(name: String, f: Config.Presentation)] =
        [("standard", .standard), ("isoCode", .isoCode), ("narrow", .narrow), ("fullName", .fullName)]
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

    /// The locales the CLDR data covers. The last three are named at the language level, matching the
    /// language-level CLDR data and avoiding the region overrides a `sw_KE`-style identifier would pull.
    package static let coveredLocaleIDs = ["en_US", "en_GB", "de_DE", "fr_FR", "ja_JP", "sw", "si", "ro"]

    /// Amounts spanning zero, one smallest unit, a typical value, a large value, and a negative
    /// value. One smallest unit is what reaches a locale's singular naming: a currency with no
    /// fraction digits is then exactly one whole unit.
    package static let amounts: [Int64] = [0, 1, 1_00, 12_34_56, -12_34_56, 1_234_567_89]

    /// Scale-spanning currencies (0/2/3 decimal places), for exercising the option cross without
    /// repeating it for every currency: that cross is currency-independent engine code.
    package static let optionCurrencies: [Currency] = [.jpy, .gbp, .bhd]

    /// Whether the CLDR data can render this cell with no ICU at all.
    ///
    /// Only a full name can be missing: every other presentation falls back to the currency's code,
    /// but CLDR leaves a handful of the currencies the library ships unnamed. A cell this returns
    /// `false` for is rendered by ICU, so comparing it against ICU proves nothing and hashing it
    /// records text that differs by platform.
    package static func isEngineCovered(
        _ currency: Currency,
        localeID: String,
        presentation: Config.Presentation
    ) -> Bool {
        guard presentation == .fullName else {
            return true
        }

        return MoneyLocalization.fullNameMoneyFormat(
            for: currency, minorUnits: 1, locale: LocaleIdentifier(localeID)
        ) != nil
    }
}
