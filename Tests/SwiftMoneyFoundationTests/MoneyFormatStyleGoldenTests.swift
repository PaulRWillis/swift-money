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
    // portable. That is only safe while the fallback stays rare, so this pins how much of the matrix
    // the engine really renders. CLDR 48 names most but not every shipped currency, and fewest in the
    // newer locales: it leaves one unnamed in English, and around a dozen in Swahili, Sinhala and
    // Romanian. The bar is a proportion, not a fixed count, so it holds as locale coverage grows.
    @Test("The data names most of the shipped currencies", arguments: FormatMatrix.coveredLocaleIDs)
    func fullNamesCoverMostCurrencies(_ localeID: String) {
        let named = Currency.allISO4217.count {
            FormatMatrix.isEngineCovered($0, localeID: localeID, presentation: .fullName)
        }

        #expect(named >= Currency.allISO4217.count * 9 / 10, "\(localeID) names only \(named)")
    }
}
