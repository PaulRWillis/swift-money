import SwiftMoneyCore
import SwiftMoneyFormatMatrix

// Non-gating intelligence, not a correctness check: CLDR is the source of truth, not ICU, so this
// never fails CI. It surfaces where a platform's bundled ICU lags the CLDR 48 data the engine
// renders from (e.g. Linux rendering XCG as "Cg." where CLDR 48, and this engine, say "Cg"). The
// correctness gate is MoneyFormatStyleGoldenTests, which hashes the engine's own output and never
// touches ICU.
let deviations = FormatMatrix.deviations(
    currencies: Currency.allISO4217,
    localeIDs: FormatMatrix.coveredLocaleIDs,
    combinations: FormatMatrix.combinations,
    amounts: FormatMatrix.amounts
)

// Foundation's own currency style drops the symbol whenever grouping is off together with a sign
// or separator (see MoneyFormatStyleModifierTests), regardless of currency, locale or amount. That
// single known defect otherwise dominates the raw cell count, so it is counted once here instead of
// printed per cell, leaving genuinely new platform/CLDR differences visible.
let novel = deviations.filter { !$0.isKnownFoundationGroupingDefect }
let knownIssueCount = deviations.count - novel.count

if novel.isEmpty {
    print("No new deviations: the engine matches ICU on every covered cell outside the known issue below.")
} else {
    let byLocale = Dictionary(grouping: novel, by: \.localeID)

    for localeID in FormatMatrix.coveredLocaleIDs {
        guard let found = byLocale[localeID], !found.isEmpty else {
            continue
        }

        print("\(localeID): \(found.count) deviation(s)")
        for deviation in found {
            print(
                "  \(deviation.currencyCode) \(deviation.combinationID) \(deviation.amount):"
                    + " engine '\(deviation.engine)' vs ICU '\(deviation.icu)'"
            )
        }
    }

    print("Total: \(novel.count) new deviation(s) across \(FormatMatrix.coveredLocaleIDs.count) locales.")
}

if knownIssueCount > 0 {
    print(
        "Also skipped \(knownIssueCount) cell(s) matching a known Foundation defect (grouping off"
            + " together with a sign or separator drops the currency symbol; see"
            + " MoneyFormatStyleModifierTests). Not printed individually."
    )
}
