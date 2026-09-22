import CLDRLocaleSkips
import Testing

@Suite("SkipReport")
struct SkipReportTests {

    private static let skipped = [
        SkippedLocale(locale: "nl", skip: .unrepresentableNumberFormat(.negativeSubpattern(pattern: "#,##0.00;-#,##0.00"))),
        SkippedLocale(locale: "ar", skip: .unrepresentableNumberFormat(.nonLatinDigits(numberingSystem: "arab"))),
        SkippedLocale(locale: "bem", skip: .noPluralRules(language: "bem")),
        SkippedLocale(locale: "aa", skip: .unrepresentableNumberFormat(.nonLatinDigits(numberingSystem: "arab"))),
    ]

    private static func report(
        skipped: [SkippedLocale] = skipped,
        candidates: Int = 10,
        unusableCurrencyCodes: Set<String> = []
    ) -> SkipReport {
        SkipReport(
            cldrVersion: "48.2.0",
            candidates: candidates,
            skipped: skipped,
            unusableCurrencyCodes: unusableCurrencyCodes
        )
    }

    @Test("Emitted is what is left after the skips")
    func emittedCountsTheRemainder() {
        #expect(Self.report().emitted == 6)
    }

    // The CLDR workflow regenerates and runs `git diff --exit-code`, so a report that reordered
    // between runs would fail at random. Input order must not reach the output.
    @Test("The rendering does not depend on the order the skips arrive in")
    func renderingIsOrderIndependent() {
        let forwards = Self.report(skipped: Self.skipped).rendered
        let backwards = Self.report(skipped: Self.skipped.reversed()).rendered

        #expect(forwards == backwards)
    }

    @Test("Locales sharing a reason are grouped under it and counted")
    func groupsByReason() {
        let rendered = Self.report().rendered

        #expect(rendered.contains("## writes amounts in digits other than 0 to 9 (2)"))
        #expect(rendered.contains("- aa: arab"))
        #expect(rendered.contains("- ar: arab"))
    }

    // Sections are ordered by name, never by how many locales fell into them: two causes with the
    // same count would otherwise have no defined order between them.
    @Test("Sections are ordered by reason, not by how many locales share one")
    func sectionsSortByReason() {
        let rendered = Self.report().rendered
        let headings = rendered.split(separator: "\n").filter { $0.hasPrefix("## ") }

        #expect(headings == headings.sorted())
    }

    @Test("Locales within a reason are ordered by name")
    func localesSortByName() {
        let entries = Self.report().rendered
            .split(separator: "\n")
            .filter { $0.hasPrefix("- ") && $0.hasSuffix("arab") }

        #expect(entries == ["- aa: arab", "- ar: arab"])
    }

    @Test("The preamble names the release and both counts")
    func preambleCarriesTheCounts() {
        let rendered = Self.report().rendered

        #expect(rendered.hasPrefix("# Locales without built-in currency formatting"))
        #expect(rendered.contains("CLDR 48.2.0"))
        #expect(rendered.contains("formats 6 of the 10 CLDR locales"))
        #expect(rendered.contains("The 4 below are left out"))
    }

    @Test("A skip whose reason says everything renders as the locale alone")
    func detaillessSkipRendersBare() {
        let rendered = Self.report(skipped: [
            SkippedLocale(locale: "kab", skip: .unrepresentablePattern(.currencyMovesForLetterSymbols, field: .standard)),
        ]).rendered

        #expect(rendered.contains("\n- kab\n"))
    }

    @Test("Unusable currency codes are listed only when there are some")
    func currencyCodeSectionIsConditional() {
        #expect(!Self.report().rendered.contains("Currency codes CLDR names"))

        let listed = Self.report(unusableCurrencyCodes: ["XBB", "XBA"]).rendered
        #expect(listed.contains("## Currency codes CLDR names that a currency cannot carry (2)"))
        #expect(listed.contains("XBA, XBB"))
    }

    @Test("A report with no skips says so rather than heading an empty list")
    func emptyReportSaysSo() {
        let rendered = Self.report(skipped: [], candidates: 8).rendered

        #expect(rendered.contains("formats 8 of the 8 CLDR locales"))
        #expect(rendered.contains("It leaves none of them out."))
        #expect(!rendered.contains("## "))
    }
}
