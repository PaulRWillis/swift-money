import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

// Locks the output of `MoneyOf.FormatStyle` against a committed per-locale hash of the engine's rendering.
// It hashes the engine's own output rather than comparing to the platform's `Decimal.FormatStyle.Currency`,
// because ICU differs by version between platforms and so cannot gate portably; the engine's output comes
// from committed CLDR data and is identical everywhere.
//
// Regenerate the digests after an intended output change: run with MONEYGOLDEN_RECORD=1 and copy the printed
// values into `golden`.
@Suite("MoneyFormatStyle golden")
struct MoneyFormatStyleGoldenTests {
    typealias Config = CurrencyFormatStyleConfiguration

    // The option cross (sign/grouping/separator) exercises currency-independent engine code, so it is
    // measured on a few scale-spanning currencies rather than all of them: JPY (0 places), GBP (2), BHD (3).
    static let optionCurrencies: [Currency] = [.jpy, .gbp, .bhd]

    static let localeIDs = ["en_US", "en_GB", "de_DE", "fr_FR", "ja_JP"]
    static let amounts: [Int64] = [0, 1_00, 12_34_56, -12_34_56, 1_234_567_89]

    static let presentations: [(name: String, f: Config.Presentation)] =
        [("standard", .standard), ("isoCode", .isoCode), ("narrow", .narrow)]
    static let signs: [(name: String, f: Config.SignDisplayStrategy)] =
        [("automatic", .automatic), ("never", .never), ("always", .always()), ("accounting", .accounting)]
    static let groupings: [(name: String, f: Config.Grouping)] =
        [("automatic", .automatic), ("never", .never)]
    static let separators: [(name: String, f: Config.DecimalSeparatorDisplayStrategy)] =
        [("automatic", .automatic), ("always", .always)]

    // One point in the presentation × sign × grouping × separator cross. Precomputed once, since it is the
    // same for every locale, so the per-locale digest walks a flat list rather than a nested loop.
    struct Combination {
        let id: String
        let presentation: Config.Presentation
        let sign: Config.SignDisplayStrategy
        let grouping: Config.Grouping
        let separator: Config.DecimalSeparatorDisplayStrategy
    }

    static let combinations: [Combination] = presentations.flatMap { p in
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

    // FNV-1a over the engine's CLDR-derived output. Regenerate with MONEYGOLDEN_RECORD=1.
    static let golden: [String: UInt64] = [
        "en_US": 0x72ea_5565_82be_017f,
        "en_GB": 0xfbaa_171e_2b04_f401,
        "de_DE": 0xf0bc_afed_42d5_794d,
        "fr_FR": 0x8c0d_569c_c980_18b9,
        "ja_JP": 0xbe80_33e4_dced_1820,
    ]

    @Test("Engine output matches the committed golden, per locale", arguments: localeIDs)
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

    static func digest(for localeID: String) -> UInt64 {
        let locale = Locale(identifier: localeID)
        var hash = FNV1a()

        // Every currency, default options, every presentation: the symbol, spacing and scale coverage.
        for currency in Currency.allISO4217 {
            let code = String(currency.code)
            for p in presentations {
                for amount in amounts {
                    let out = Money.FormatStyle().locale(locale).presentation(p.f)
                        .format(Money(minorUnits: amount, currency: currency))
                    hash.combine("\(code)|\(p.name)|\(amount)=\(out)")
                }
            }
        }

        // Representative currencies, every option combination: the sign/grouping/separator coverage.
        for currency in optionCurrencies {
            let code = String(currency.code)
            for combination in Self.combinations {
                for amount in amounts {
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
