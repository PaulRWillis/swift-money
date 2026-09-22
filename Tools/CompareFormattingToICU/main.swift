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

// CI shards the locales across parallel legs so the report scales past a handful of locales without
// timing out. `ICU_SHARD_COUNT` and `ICU_SHARD_INDEX` select one shard; absent (or a count of one)
// runs every covered locale, which is also what an older base commit's tool does. Sharding narrows
// which locales are walked, not the shape of a line, so a shard stays comparable to the same shard on
// another commit.
let environment = ProcessInfo.processInfo.environment
let localeIDs: [String]
if let count = environment["ICU_SHARD_COUNT"].flatMap(Int.init), count > 1,
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
