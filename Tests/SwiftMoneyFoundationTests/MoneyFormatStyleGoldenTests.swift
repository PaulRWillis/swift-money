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

    @Test("Engine output matches the committed golden, per locale", arguments: FormatMatrix.goldenLocaleIDs)
    func matchesGolden(_ localeID: String) {
        let digest = FormatMatrix.goldenDigest(forLocale: localeID)

        #expect(
            digest == goldenDigests[localeID],
            "\(localeID): golden mismatch (regenerate with `swift run RecordGoldenDigests`). got 0x\(String(digest, radix: 16))"
        )
    }

    // A cell the data cannot render falls back to ICU, and a digest of ICU's text would not be
    // portable, so a locale carries its weight only where it names some currencies itself. How many
    // varies enormously: a rich locale names nearly every shipped currency, a thin one a handful, and
    // a locale inheriting CLDR's root names none at all, which ICU also does, so its output is right
    // rather than missing.
    //
    // No per-locale bar can hold across that spread, and the digests say only that a locale's output
    // moved, never in which direction. Two committed totals say it instead: coverage that shrinks
    // fails, and a locale that stops naming anything has to be accounted for rather than slip past.
    @Test("The engine names as many currencies as were recorded")
    func namedCurrencyTotalHolds() {
        #expect(
            FormatMatrix.namedCurrencyTotal == goldenNamedCurrencyTotal,
            "regenerate with `swift run RecordGoldenDigests`. got \(FormatMatrix.namedCurrencyTotal)"
        )
    }

    @Test("As many covered locales name nothing as were recorded")
    func localesNamingNothingHolds() {
        #expect(
            FormatMatrix.localesNamingNoCurrency == goldenLocalesNamingNoCurrency,
            "regenerate with `swift run RecordGoldenDigests`. got \(FormatMatrix.localesNamingNoCurrency)"
        )
    }
}
