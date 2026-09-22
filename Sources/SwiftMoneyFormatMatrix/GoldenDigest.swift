import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import SwiftMoneyLocalization

extension FormatMatrix {
    /// A portable FNV-1a hash of everything `MoneyOf.FormatStyle` renders for one locale: every
    /// currency across the presentations, and the representative currencies across the option cross.
    ///
    /// The engine's own output is hashed rather than the platform's `Decimal.FormatStyle.Currency`,
    /// because ICU differs by version between platforms and so cannot gate portably; the engine reads
    /// committed CLDR data and renders identically everywhere. The `RecordGoldenDigests` tool writes
    /// these into a committed file, and the golden test fails when a locale's digest drifts from it.
    package static func goldenDigest(forLocale localeID: String) -> UInt64 {
        let locale = Locale(identifier: localeID)
        var hash = FNV1a()

        // Every currency, default options, every presentation: the symbol, spacing and scale coverage.
        for currency in Currency.allISO4217 {
            let code = String(currency.code)
            for p in presentations {
                let covered = isEngineCovered(currency, localeID: localeID, presentation: p.f)

                for amount in amounts {
                    let out = covered
                        ? Money.FormatStyle().locale(locale).presentation(p.f)
                            .format(Money(minorUnits: amount, currency: currency))
                        : uncovered
                    hash.combine("\(code)|\(p.name)|\(amount)=\(out)")
                }
            }
        }

        // Representative currencies, every option combination: the sign/grouping/separator/precision
        // coverage.
        for currency in optionCurrencies {
            let code = String(currency.code)
            for combination in combinations {
                let covered = isEngineCovered(currency, localeID: localeID, combination: combination)
                let style = combination.style(locale: locale)

                for amount in amounts {
                    let out = covered
                        ? style.format(Money(minorUnits: amount, currency: currency))
                        : uncovered
                    hash.combine("\(code)|\(combination.id)|\(amount)=\(out)")
                }
            }
        }

        return hash.value
    }

    /// What a cell the CLDR data cannot render hashes as. Hashing ICU's rendering instead would tie the
    /// digest to a platform's ICU version, which is what the golden test exists to avoid; hashing a
    /// marker still catches a name that disappears, since the cell moves from its text to this.
    static let uncovered = "(not in the data)"
}
