import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization

/// Currency-format inputs (option cross, locales, amounts), so multiple consumers share one set
/// instead of drifting onto different ones.
package enum FormatMatrix {
    /// The vocabulary `Decimal.FormatStyle.Currency` and `MoneyOf.FormatStyle` share.
    package typealias Config = CurrencyFormatStyleConfiguration

    /// One point of the presentation x sign x grouping x separator x precision cross.
    package struct Combination {
        package let id: String
        package let presentation: Config.Presentation
        package let sign: Config.SignDisplayStrategy
        package let grouping: Config.Grouping
        package let separator: Config.DecimalSeparatorDisplayStrategy

        /// The precision to apply, or `nil` for the currency's own scale.
        package let precision: Config.Precision?

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

    /// The precision axis: the currency's own scale, then fixed lengths that round below it (0), pad a
    /// zero-scale currency and round a three-scale one (2), and pad past every shipped scale (4).
    package static let precisions: [(name: String, f: Config.Precision?)] = [
        ("defaultPrecision", nil),
        ("fixed0", .fractionLength(0)),
        ("fixed2", .fractionLength(2)),
        ("fixed4", .fractionLength(4)),
    ]

    /// The full cross, precomputed once since it is the same for every locale.
    package static let combinations: [Combination] = presentations.flatMap { p in
        signs.flatMap { s in
            groupings.flatMap { g in
                separators.flatMap { d in
                    precisions.map { pr in
                        Combination(
                            id: "\(p.name)|\(s.name)|\(g.name)|\(d.name)|\(pr.name)",
                            presentation: p.f, sign: s.f, grouping: g.f, separator: d.f, precision: pr.f
                        )
                    }
                }
            }
        }
    }

    /// The locales the CLDR data covers, read from the blob so the list grows with the data rather than
    /// being maintained by hand. The identifiers are the ones the data ships (`en`, `en-GB`, …).
    package static let coveredLocaleIDs = MoneyLocalization.coveredLocaleIdentifiers

    /// Representative locale-with-numbering-system identifiers, exercising each resolution shape the engine
    /// renders: an imposing system (`arab`), reuse systems on a Latin-default locale (`nkoo`, `deva`), each
    /// on a non-Latin-default locale (`beng`, `deva`), an imposing default (`arabext`), and a reuse system
    /// on an imposing-default locale (`ur-IN@latn`, which must revert to that locale's Latin separators).
    /// Every one renders through the engine, so its golden digest stays portable.
    package static let numberingSystemLocaleIDs = [
        "en_GB@numbers=arab",
        "en_GB@numbers=nkoo",
        "en_GB@numbers=deva",
        "bn@numbers=beng",
        "ne@numbers=deva",
        "fa-AF@numbers=arabext",
        "ur-IN@numbers=latn",
    ]

    /// Every locale the golden test and the ICU report walk: the covered locales in their own default
    /// system, plus the numbering-system combinations above.
    package static let goldenLocaleIDs = coveredLocaleIDs + numberingSystemLocaleIDs

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

    /// Whether the engine renders this whole cell with no ICU, precision included.
    ///
    /// A full name at an explicit fraction length routes to ICU regardless of the currency: the plural
    /// form follows the currency scale, which a fixed length would contradict. This mirrors
    /// `MoneyOf.FormatStyle.engineRenderInputs`, the single place the real fallback is decided.
    package static func isEngineCovered(
        _ currency: Currency,
        localeID: String,
        combination: Combination
    ) -> Bool {
        if combination.presentation == .fullName, combination.precision != nil {
            return false
        }

        return isEngineCovered(currency, localeID: localeID, presentation: combination.presentation)
    }
}
