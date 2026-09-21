import Foundation
import SwiftMoneyCore
import SwiftMoneyFormatMatrix
import SwiftMoneyFoundation
import Testing

// Locks the output of `MoneyOf.FormatStyle` against a committed per-locale hash of the engine's rendering.
// It hashes the engine's own output rather than comparing to the platform's `Decimal.FormatStyle.Currency`,
// because ICU differs by version between platforms and so cannot gate portably; the engine's output comes
// from committed CLDR data and is identical everywhere.
//
// The currencies/locales/amounts/option cross live in `FormatMatrix`, so consumers of it can't
// drift onto different inputs.
//
// Regenerate the digests after an intended output change: run with MONEYGOLDEN_RECORD=1 and copy the printed
// values into `golden`.
@Suite("MoneyFormatStyle golden")
struct MoneyFormatStyleGoldenTests {

    // FNV-1a over the engine's CLDR-derived output. Regenerate with MONEYGOLDEN_RECORD=1.
    static let golden: [String: UInt64] = [
        "en_US": 0x1a34_d11a_de90_1160,
        "en_GB": 0xba8c_1b25_6698_de67,
        "de_DE": 0xc81b_7590_f342_8ecd,
        "fr_FR": 0x1a62_c651_51fa_bfd3,
        "ja_JP": 0x36a9_9c75_e2c1_88dd,
        "sw": 0x82c0_fad7_74f4_6c4d,
        "si": 0x06dc_25c2_1f7d_c509,
        "ro": 0x1fd2_f52d_2cd4_e716,
    ]

    @Test("Engine output matches the committed golden, per locale", arguments: FormatMatrix.coveredLocaleIDs)
    func matchesGolden(_ localeID: String) {
        let digest = Self.digest(for: localeID)

        if ProcessInfo.processInfo.environment["MONEYGOLDEN_RECORD"] != nil {
            print("GOLDEN \(localeID) = 0x\(String(digest, radix: 16))")
        }

        #expect(
            digest == Self.golden[localeID],
            "\(localeID): golden mismatch (regenerate with MONEYGOLDEN_RECORD=1). got 0x\(String(digest, radix: 16))"
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

    // What a cell the CLDR data cannot render hashes as. Hashing ICU's rendering instead would tie the
    // digest to a platform's ICU version, which is what this test exists to avoid; hashing a marker
    // still catches a name that disappears, since the cell moves from its text to this.
    static let uncovered = "(not in the data)"

    static func digest(for localeID: String) -> UInt64 {
        let locale = Locale(identifier: localeID)
        var hash = FNV1a()

        // Every currency, default options, every presentation: the symbol, spacing and scale coverage.
        for currency in Currency.allISO4217 {
            let code = String(currency.code)
            for p in FormatMatrix.presentations {
                let covered = FormatMatrix.isEngineCovered(currency, localeID: localeID, presentation: p.f)

                for amount in FormatMatrix.amounts {
                    let out = covered
                        ? Money.FormatStyle().locale(locale).presentation(p.f)
                            .format(Money(minorUnits: amount, currency: currency))
                        : Self.uncovered
                    hash.combine("\(code)|\(p.name)|\(amount)=\(out)")
                }
            }
        }

        // Representative currencies, every option combination: the sign/grouping/separator coverage.
        for currency in FormatMatrix.optionCurrencies {
            let code = String(currency.code)
            for combination in FormatMatrix.combinations {
                for amount in FormatMatrix.amounts {
                    let out = Money.FormatStyle().locale(locale)
                        .presentation(combination.presentation).sign(strategy: combination.sign)
                        .grouping(combination.grouping).decimalSeparator(strategy: combination.separator)
                        .format(Money(minorUnits: amount, currency: currency))
                    hash.combine("\(code)|\(combination.id)|\(amount)=\(out)")
                }
            }
        }

        return hash.value
    }
}

// A deterministic hash (unlike `Hasher`, which is seeded per process), so the digest is reproducible across
// runs and platforms.
struct FNV1a {
    private(set) var value: UInt64 = 0xcbf2_9ce4_8422_2325

    mutating func combine(_ string: String) {
        for byte in string.utf8 {
            value = (value ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
        }
        value = (value ^ 0x0a) &* 0x0000_0100_0000_01b3
    }
}
