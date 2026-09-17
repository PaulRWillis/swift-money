import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

// The portable gate for the wired `MoneyOf.FormatStyle`. It hashes the engine's output — which is derived
// from our committed CLDR data, so it is identical on every platform — over a factored cross of currencies,
// presentations, sign/grouping/separator options and amounts, and asserts one digest per locale. ICU is
// deliberately NOT the oracle here: a platform's ICU can lag CLDR (Linux renders XCG as "Cg." where CLDR 48
// and we say "Cg"), so gating on ICU is not portable. The engine-vs-ICU comparison lives in the non-gating
// deviation report instead. `fullName` is absent until it is ported to the engine (Phase D); it then joins
// this matrix as a fourth presentation.
//
// Regenerate the digests after an intended output change: run with MONEYGOLDEN_RECORD=1 and copy the
// printed values into `golden` below.
@Suite("MoneyFormatStyle golden")
struct MoneyFormatStyleGoldenTests {
    typealias Config = CurrencyFormatStyleConfiguration

    // Every shipped ISO currency. Update if the ISO 4217 table grows.
    static let currencies: [Currency] = [
        .aed, .afn, .all, .amd, .aoa, .ars, .aud, .awg, .azn, .bam, .bbd, .bdt, .bhd, .bif, .bmd, .bnd,
        .bob, .bov, .brl, .bsd, .btn, .bwp, .byn, .bzd, .cad, .cdf, .che, .chf, .chw, .clf, .clp, .cny,
        .cop, .cou, .crc, .cup, .cve, .czk, .djf, .dkk, .dop, .dzd, .egp, .ern, .etb, .eur, .fjd, .fkp,
        .gbp, .gel, .ghs, .gip, .gmd, .gnf, .gtq, .gyd, .hkd, .hnl, .htg, .huf, .idr, .ils, .inr, .iqd,
        .irr, .isk, .jmd, .jod, .jpy, .kes, .kgs, .khr, .kmf, .kpw, .krw, .kwd, .kyd, .kzt, .lak, .lbp,
        .lkr, .lrd, .lsl, .lyd, .mad, .mdl, .mga, .mkd, .mmk, .mnt, .mop, .mru, .mur, .mvr, .mwk, .mxn,
        .mxv, .myr, .mzn, .nad, .ngn, .nio, .nok, .npr, .nzd, .omr, .pab, .pen, .pgk, .php, .pkr, .pln,
        .pyg, .qar, .ron, .rsd, .rub, .rwf, .sar, .sbd, .scr, .sdg, .sek, .sgd, .shp, .sle, .sos, .srd,
        .ssp, .stn, .svc, .syp, .szl, .thb, .tjs, .tmt, .tnd, .top, .ttd, .twd, .tzs, .uah, .ugx, .usd,
        .usn, .uyi, .uyu, .uyw, .uzs, .ved, .ves, .vnd, .vuv, .wst, .xad, .xaf, .xcd, .xcg, .xof, .xpf,
        .yer, .zar, .zmw, .zwg,
    ]

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

    // FNV-1a over the engine's CLDR-derived output. Regenerate with MONEYGOLDEN_RECORD=1.
    static let golden: [String: UInt64] = [
        "en_US": 0x8bc4_0f59_310b_1a35,
        "en_GB": 0xd0d5_0c45_35d0_6433,
        "de_DE": 0x9888_660d_570c_0dff,
        "fr_FR": 0x0042_e08b_1c80_9041,
        "ja_JP": 0x4b20_c1ed_aeca_c6b2,
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
        for currency in currencies {
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
            for p in presentations {
                for s in signs {
                    for g in groupings {
                        for d in separators {
                            for amount in amounts {
                                let out = Money.FormatStyle().locale(locale).presentation(p.f)
                                    .sign(strategy: s.f).grouping(g.f).decimalSeparator(strategy: d.f)
                                    .format(Money(minorUnits: amount, currency: currency))
                                hash.combine("\(code)|\(p.name)|\(s.name)|\(g.name)|\(d.name)|\(amount)=\(out)")
                            }
                        }
                    }
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
