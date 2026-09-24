/// The tally of a run over one or more General Decimal Arithmetic files.
///
/// Merges across files so a single `@Test` can assert on the whole operation at once: no vector failed,
/// and enough ran that the filters did not quietly empty the set.
struct GDASummary: Sendable {
    private(set) var passed = 0
    private(set) var skipped = 0
    private(set) var skipReasons: [GDASkipReason: Int] = [:]

    /// The id and detail of every vector whose computed result did not match the corpus.
    private(set) var failures: [String] = []

    var failed: Int { failures.count }

    mutating func recordPass() {
        passed += 1
    }

    mutating func recordSkip(_ reason: GDASkipReason) {
        skipped += 1
        skipReasons[reason, default: 0] += 1
    }

    mutating func recordFailure(_ detail: String) {
        failures.append(detail)
    }

    mutating func merge(_ other: GDASummary) {
        passed += other.passed
        skipped += other.skipped
        failures += other.failures
        for (reason, count) in other.skipReasons {
            skipReasons[reason, default: 0] += count
        }
    }

    /// A one-line breakdown for the test log, so a reviewer sees what ran and what was set aside.
    var summaryLine: String {
        let reasons = GDASkipReason.allCases
            .compactMap { reason in skipReasons[reason].map { "\(reason.rawValue): \($0)" } }
            .joined(separator: ", ")
        let skips = reasons.isEmpty ? "" : " (\(reasons))"
        return "passed: \(passed), failed: \(failed), skipped: \(skipped)\(skips)"
    }
}
