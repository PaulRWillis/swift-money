import SwiftMoneyCore
import SwiftMoneyFormatMatrix
import Testing

// Locks the output of `MoneyOf.FormatStyle` against a committed per-locale hash of the engine's rendering.
// It hashes the engine's own output rather than comparing to the platform's `Decimal.FormatStyle.Currency`,
// because ICU differs by version between platforms and so cannot gate portably; the engine's output comes
// from committed CLDR data and is identical everywhere.
//
// The digest itself and the currencies/locales/amounts/option cross it walks live in `FormatMatrix`, so
// consumers of it can't drift onto different inputs. The committed digests live in the generated
// `goldenDigests`; regenerate them after an intended output change with `swift run RecordGoldenDigests`.
@Suite("MoneyFormatStyle golden")
struct MoneyFormatStyleGoldenTests {

    @Test("Engine output matches the committed golden, per locale", arguments: FormatMatrix.coveredLocaleIDs)
    func matchesGolden(_ localeID: String) {
        let digest = FormatMatrix.goldenDigest(forLocale: localeID)

        #expect(
            digest == goldenDigests[localeID],
            "\(localeID): golden mismatch (regenerate with `swift run RecordGoldenDigests`). got 0x\(String(digest, radix: 16))"
        )
    }

    // A cell the data cannot render falls back to ICU, and a digest of ICU's text would not be
    // portable, so a locale carries its weight only where it names some currencies itself. How many
    // varies widely: a rich locale names nearly every shipped currency, a thin CLDR locale only a
    // handful, and both are legitimate. The bar is therefore one: a locale that names nothing renders
    // no full name through the engine at all, which is a real bug. An aggregate proportion can tighten
    // this once wide coverage shows the real distribution.
    @Test("Every covered locale names at least one currency", arguments: FormatMatrix.coveredLocaleIDs)
    func fullNamesCoverAtLeastOneCurrency(_ localeID: String) {
        let named = Currency.allISO4217.count {
            FormatMatrix.isEngineCovered($0, localeID: localeID, presentation: .fullName)
        }

        #expect(named >= 1, "\(localeID) names no currencies")
    }
}
