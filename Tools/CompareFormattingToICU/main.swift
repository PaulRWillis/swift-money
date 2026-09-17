import SwiftMoneyCore
import SwiftMoneyFormatMatrix

// Non-gating: always exits 0. The correctness gate is MoneyFormatStyleGoldenTests, which never
// touches ICU.
let deviations = FormatMatrix.deviations(
    currencies: Currency.allISO4217,
    localeIDs: FormatMatrix.coveredLocaleIDs,
    combinations: FormatMatrix.combinations,
    amounts: FormatMatrix.amounts
)

// One already-known defect (see MoneyFormatStyleModifierTests) otherwise dominates the count, so
// it's reported once below instead of per cell.
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
