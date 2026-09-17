import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// Exhaustive parity between the non-ICU engine (via `MoneyOf.FormatStyle`) and ICU, across the full cross
// of every built-in currency, every covered locale, and every mappable formatting option. ICU is a
// cross-check, not the source of truth: where CLDR 48 and the OS ICU legitimately differ, or where
// Foundation's own currency style has a defect the engine does not share, we assert the engine's
// (CLDR-correct) output instead of blind equality. Any cell that matches none of those expectations is
// collected and surfaced.
@Suite("MoneyFormatStyle engine parity")
struct MoneyFormatStyleEngineParityTests {

    // Test-only list of every shipped ISO currency. Update it if the ISO 4217 table grows.
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

    static let localeIDs = ["en_US", "en_GB", "de_DE", "fr_FR", "ja_JP"]
    static let amounts: [Int64] = [0, 1_00, 12_34_56, -12_34_56, 1_234_567_89]

    typealias Config = CurrencyFormatStyleConfiguration
    static let presentations: [(name: String, f: Config.Presentation)] =
        [("standard", .standard), ("isoCode", .isoCode), ("narrow", .narrow)]
    static let signs: [(name: String, f: Config.SignDisplayStrategy)] =
        [("automatic", .automatic), ("never", .never), ("always", .always()), ("accounting", .accounting)]
    static let groupings: [(name: String, f: Config.Grouping)] =
        [("automatic", .automatic), ("never", .never)]
    static let separators: [(name: String, f: Config.DecimalSeparatorDisplayStrategy)] =
        [("automatic", .automatic), ("always", .always)]

    // Foundation drops the currency symbol when grouping is off beside another set option. The engine does
    // not; there we require it keeps the symbol rather than matching ICU.
    static func foundationDropsSymbol(sign: String, grouping: String, separator: String) -> Bool {
        grouping == "never" && (sign != "automatic" || separator == "always")
    }

    static func icu(_ money: Money, _ localeID: String, _ p: Config.Presentation, _ s: Config.SignDisplayStrategy, _ g: Config.Grouping, _ d: Config.DecimalSeparatorDisplayStrategy) -> String {
        let places = money.currency.unitScale.decimalPlaces
        var style = Decimal.FormatStyle.Currency(code: String(money.currency.code), locale: Locale(identifier: localeID))
            .precision(.fractionLength(places))
        if p != .standard { style = style.presentation(p) }
        if g != .automatic { style = style.grouping(g) }
        if s != .automatic { style = style.sign(strategy: s) }
        if d != .automatic { style = style.decimalSeparator(strategy: d) }
        let divisor = Decimal(sign: .plus, exponent: places, significand: 1)
        return style.format(Decimal(money.minorUnits) / divisor)
    }

    @Test("Engine matches ICU across every currency, locale and option", arguments: currencies)
    func parity(_ currency: Currency) {
        let code = String(currency.code)
        var surprises: [String] = []

        for localeID in Self.localeIDs {
            let locale = Locale(identifier: localeID)
            for p in Self.presentations {
                let symbol = MoneyLocalization.moneyFormat(
                    for: currency, locale: LocaleIdentifier(localeID), presentation: Self.enginePresentation(p.name)
                )?.symbol ?? code

                for s in Self.signs {
                    for g in Self.groupings {
                        for d in Self.separators {
                            let style = Money.FormatStyle().locale(locale)
                                .presentation(p.f).sign(strategy: s.f).grouping(g.f).decimalSeparator(strategy: d.f)

                            for amount in Self.amounts {
                                let money = Money(minorUnits: amount, currency: currency)
                                let engine = style.format(money)
                                let cell = "\(localeID)/\(code)/\(p.name)/\(s.name)/\(g.name)/\(d.name) \(amount)"

                                // Known CLDR-vs-OS drift: ja JPY standard symbol is the fullwidth ￥.
                                if localeID == "ja_JP", code == "JPY", p.name == "standard" {
                                    if !engine.contains("\u{FFE5}") { surprises.append("no ￥: \(cell) -> '\(engine)'") }
                                    continue
                                }

                                let icu = Self.icu(money, localeID, p.f, s.f, g.f, d.f)

                                if Self.foundationDropsSymbol(sign: s.name, grouping: g.name, separator: d.name),
                                   !icu.contains(symbol) {
                                    // Foundation dropped the symbol; the engine must keep it.
                                    if !engine.contains(symbol) { surprises.append("engine dropped symbol: \(cell) -> '\(engine)'") }
                                    continue
                                }

                                if engine != icu { surprises.append("\(cell): '\(engine)' vs ICU '\(icu)'") }
                            }
                        }
                    }
                }
            }
        }

        #expect(surprises.isEmpty, "\(code): \(surprises.count) mismatch(es); first: \(surprises.prefix(3))")
    }

    static func enginePresentation(_ name: String) -> CurrencyPresentation {
        switch name {
        case "isoCode": .isoCode
        case "narrow": .narrow
        default: .standard
        }
    }
}
