import SwiftMoneyCore
import SwiftMoneyFormatMatrix

// Non-gating: always exits 0.
//
// One deviation per line, sorted, so two runs of this tool can be compared by diffing their output.
// Anything that is not a deviation is a `#` line, which a comparison drops.
let deviations = FormatMatrix.deviations(
    currencies: Currency.allISO4217,
    localeIDs: FormatMatrix.coveredLocaleIDs,
    combinations: FormatMatrix.combinations,
    amounts: FormatMatrix.amounts
)

// A known defect dominates the raw count, so it is counted once rather than listed per cell.
let reportable = deviations.filter { !$0.isKnownFoundationGroupingDefect }
let knownIssueCount = deviations.count - reportable.count

for line in reportable.map(\.reportLine).sorted() {
    print(line)
}

print("# \(reportable.count) deviation(s) across \(FormatMatrix.coveredLocaleIDs.count) locales.")

if knownIssueCount > 0 {
    print(
        "# Not listed: \(knownIssueCount) cell(s) matching a known Foundation defect (grouping off"
            + " together with a sign or separator drops the currency symbol; see"
            + " MoneyFormatStyleModifierTests)."
    )
}
