import SwiftMoneyCore
import SwiftMoneyFormatMatrix

// Non-gating: always exits 0.
//
// One line per locale, currency and presentation that disagrees with ICU, sorted, so two runs of this
// tool can be compared by diffing their output. Anything that is not a deviation is a `#` line, which
// a comparison drops.
//
// The version below rises whenever a line's shape changes. A comparison that sees two versions
// reports nothing rather than every line at once, since a reshaped line is not a changed deviation.
print("# format: 3")
let deviations = FormatMatrix.deviations(
    currencies: Currency.allISO4217,
    localeIDs: FormatMatrix.coveredLocaleIDs,
    combinations: FormatMatrix.combinations,
    amounts: FormatMatrix.amounts
)

// A known defect dominates the raw count, so it is counted once rather than listed per cell.
let reportable = deviations.filter { !$0.isKnownFoundationGroupingDefect }
let knownIssueCount = deviations.count - reportable.count

let lines = FormatMatrix.summaryLines(for: reportable)

for line in lines {
    print(line)
}

print("# \(reportable.count) deviation(s) in \(lines.count) group(s) across \(FormatMatrix.coveredLocaleIDs.count) locales.")

if knownIssueCount > 0 {
    print(
        "# Not listed: \(knownIssueCount) cell(s) matching a known Foundation defect (grouping off"
            + " together with a sign or separator drops the currency symbol; see"
            + " MoneyFormatStyleModifierTests)."
    )
}
