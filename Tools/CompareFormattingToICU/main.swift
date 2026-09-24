import Foundation
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

// Which locales to walk, in precedence order:
//   1. `ICU_LOCALES` (comma or space separated) audits just that subset and skips sharding, so a
//      coverage change can be checked against ICU without walking every covered locale. A named locale
//      that is not covered is reported on a `#` line and skipped.
//   2. `ICU_SHARD_COUNT` + `ICU_SHARD_INDEX` select one shard, which is how CI splits the full report
//      across parallel legs so it scales past a handful of locales without timing out.
//   3. neither: every covered locale, which is also what an older base commit's tool does.
// None of these change the shape of a line, only which locales are walked, so any subset stays
// comparable to the same locales on another commit.
let environment = ProcessInfo.processInfo.environment
let requestedLocales = (environment["ICU_LOCALES"] ?? "")
    .split(whereSeparator: { $0 == "," || $0 == " " })
    .map(String.init)

let localeIDs: [String]
if !requestedLocales.isEmpty {
    let resolved = FormatMatrix.coveredLocales(among: requestedLocales)
    for id in resolved.unknown {
        print("# requested but not covered: \(id)")
    }
    localeIDs = resolved.selected
} else if let count = environment["ICU_SHARD_COUNT"].flatMap(Int.init), count > 1,
          let index = environment["ICU_SHARD_INDEX"].flatMap(Int.init) {
    localeIDs = FormatMatrix.localeIDs(inShard: index, of: count)
} else {
    localeIDs = FormatMatrix.coveredLocaleIDs
}

let deviations = FormatMatrix.deviations(
    currencies: Currency.allISO4217,
    localeIDs: localeIDs,
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

print("# \(reportable.count) deviation(s) in \(lines.count) group(s) across \(localeIDs.count) locales.")

if knownIssueCount > 0 {
    print(
        "# Not listed: \(knownIssueCount) cell(s) matching a known Foundation defect (grouping off"
            + " together with a sign or separator drops the currency symbol; see"
            + " MoneyFormatStyleModifierTests)."
    )
}
