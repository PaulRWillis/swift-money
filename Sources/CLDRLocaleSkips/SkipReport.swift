/// The committed account of which CLDR locales the generator left out, and why.
///
/// It is written beside the generated tables and regenerated with them, so the CLDR workflow's
/// `git diff --exit-code` keeps it honest: a locale that starts or stops being representable shows up
/// as a diff rather than as silence.
///
/// Everything it prints is ordered by name, never by count and never by dictionary order, because a
/// report whose order moved between runs would fail that check at random.
package struct SkipReport: Equatable, Sendable {
    private let cldrVersion: String
    private let candidates: Int
    private let skipped: [SkippedLocale]
    private let unusableCurrencyCodes: Set<UnusableCurrencyCode>

    /// - Parameters:
    ///   - cldrVersion: The release the tables were built from.
    ///   - candidates: How many locales the generator considered.
    ///   - skipped: The ones it could not build, in any order.
    ///   - unusableCurrencyCodes: Codes CLDR names that the tables cannot hold.
    package init(
        cldrVersion: String,
        candidates: Int,
        skipped: [SkippedLocale],
        unusableCurrencyCodes: Set<UnusableCurrencyCode> = []
    ) {
        self.cldrVersion = cldrVersion
        self.candidates = candidates
        self.skipped = skipped
        self.unusableCurrencyCodes = unusableCurrencyCodes
    }

    /// How many locales the generator emitted.
    package var emitted: Int {
        candidates - skipped.count
    }

    /// The whole report as Markdown.
    package var rendered: String {
        ([preamble] + reasonSections + currencyCodeSection).joined(separator: "\n\n") + "\n"
    }

    private var preamble: String {
        """
        # Locales without built-in currency formatting

        Generated from CLDR \(cldrVersion) by GenerateSwiftMoneyLocalization. Do not edit by hand.
        Regenerate with: (cd Tools/cldr && npm ci) && swift run GenerateSwiftMoneyLocalization

        The engine formats \(emitted) of the \(candidates) CLDR locales this build reads. \(remainder)
        """
    }

    private var remainder: String {
        guard !skipped.isEmpty else {
            return "It leaves none of them out."
        }

        return """
            The \(skipped.count) below are left out, each because it writes something the packed tables \
            have no shape for. They keep the ICU fallback, and rejoin the list on their own once that \
            shape exists.
            """
    }

    // One section per cause, headed by the cause and the number of locales sharing it.
    private var reasonSections: [String] {
        let byReason = Dictionary(grouping: skipped) { $0.skip.reason }

        return byReason.keys.sorted().map { reason in
            let entries = byReason[reason, default: []]
                .sorted { $0.locale < $1.locale }
                .map(Self.entry)

            return (["## \(reason) (\(entries.count))"] + entries).joined(separator: "\n")
        }
    }

    private var currencyCodeSection: [String] {
        guard !unusableCurrencyCodes.isEmpty else {
            return []
        }

        let lines = unusableCurrencyCodes.map(Self.line).sorted()

        return ["""
            ## Currency codes CLDR names that the tables cannot hold (\(unusableCurrencyCodes.count))

            \(lines.joined(separator: "\n"))
            """]
    }

    /// Returns one unusable code as a list item: the code, then why the tables can't hold it.
    ///
    /// - Parameter code: The unusable code.
    /// - Returns: The list item, such as `- USDT: longer than the tables hold`.
    private static func line(_ code: UnusableCurrencyCode) -> String {
        switch code {
        case .notACurrencyCode(let text):
            "- \(text): not a currency code"
        case .longerThanTheTablesHold(let currencyCode):
            "- \(currencyCode): longer than the tables hold"
        }
    }

    private static func entry(_ skipped: SkippedLocale) -> String {
        let detail = skipped.skip.detail

        return detail.isEmpty ? "- \(skipped.locale)" : "- \(skipped.locale): \(detail)"
    }
}
