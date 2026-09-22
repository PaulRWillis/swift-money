import CLDRCurrencyPatterns
import CLDRLocaleSkips
import SwiftMoneyLocalization
import Testing

@Suite("LocaleSkip")
struct LocaleSkipTests {

    // The report groups on the reason, so two skips that mean different things must not collide, and
    // one reason must never be a prefix of the detail that belongs to another.
    @Test("Every case gives a distinct, non-empty reason")
    func reasonsAreDistinct() {
        let reasons = Self.oneOfEachCase.map(\.reason)

        #expect(reasons.allSatisfy { !$0.isEmpty })
        #expect(Set(reasons).count == reasons.count)
    }

    // The whole point of the split: a locale's own pattern text in the reason would put every locale
    // in a group of one, which is the failure mode the report exists to avoid.
    @Test("A reason carries nothing specific to the locale that raised it")
    func reasonsCarryNoDetail() {
        let skips = [
            LocaleSkip.nonLatinDigits(numberingSystem: "arab"),
            .negativeSubpattern(pattern: "#,##0.00;(#,##0.00)"),
            .noPluralRules(language: "bem"),
            .noCurrencyPlaceholder(pattern: "#,##0.00"),
            .unreadableCurrencySpacing(rule: "currencyMatch [:^S:]"),
        ]

        for skip in skips {
            #expect(!skip.reason.contains(skip.detail), "\(skip.reason) repeats its detail")
        }
    }

    // Two locales rejected for the same shape have to share a reason exactly, whatever patterns they
    // published, or the grouping degenerates.
    @Test("Two locales rejected for the same shape share a reason")
    func sameShapeSharesReason() {
        let kab = LocaleSkip.unrepresentablePattern(.currencyMovesForLetterSymbols, field: .standard)
        let khq = LocaleSkip.unrepresentablePattern(.currencyMovesForLetterSymbols, field: .standard)
        let grouping = LocaleSkip.unrepresentablePattern(.groupingChangesForLetterSymbols, field: .standard)

        #expect(kab.reason == khq.reason)
        #expect(kab.reason != grouping.reason)
    }

    @Test("The same shape in the two pattern fields reads as two reasons")
    func patternFieldSeparatesReasons() {
        let standard = LocaleSkip.unrepresentablePattern(.currencyMovesForLetterSymbols, field: .standard)
        let accounting = LocaleSkip.unrepresentablePattern(.currencyMovesForLetterSymbols, field: .accounting)

        #expect(standard.reason != accounting.reason)
    }

    // A no-break space and a plain space are the same glyph on a page, and most of what a detail
    // carries is spacing, so a reader needs them spelled out.
    @Test("Detail escapes characters outside printable ASCII")
    func detailEscapesInvisibleCharacters() {
        let skip = LocaleSkip.negativeSubpattern(pattern: "\u{200F}-#,##0.00\u{00A0}\u{00A4}")

        #expect(skip.detail == "\\u{200F}-#,##0.00\\u{A0}\\u{A4}")
    }

    @Test("An empty gap is named rather than written")
    func emptyGapIsNamed() {
        let skip = LocaleSkip.multipleNameGaps([.none, .asciiSpace])

        #expect(skip.detail == "(none), \\u{20}")
    }

    @Test("An unmodelled pattern carries both patterns as its detail")
    func unmodelledCarriesBothPatterns() {
        let skip = LocaleSkip.unrepresentablePattern(
            .unmodelled(pattern: "#,##0.00\u{00A4}", letterSymbolPattern: "#,##0.00-\u{00A4}"),
            field: .standard
        )

        #expect(skip.detail == "#,##0.00\\u{A4} against #,##0.00-\\u{A4}")
    }

    // The two cases that say everything in the reason; the report renders those as the locale alone.
    @Test("A named rearrangement needs no detail")
    func namedRearrangementHasNoDetail() {
        #expect(LocaleSkip.unrepresentablePattern(.currencyMovesForLetterSymbols, field: .standard).detail.isEmpty)
        #expect(LocaleSkip.unrepresentablePattern(.groupingChangesForLetterSymbols, field: .standard).detail.isEmpty)
    }

    @Test("Description joins the reason and the detail")
    func descriptionJoinsBoth() {
        let withDetail = LocaleSkip.noPluralRules(language: "bem")
        let withoutDetail = LocaleSkip.unrepresentablePattern(.currencyMovesForLetterSymbols, field: .standard)

        #expect(withDetail.description == "\(withDetail.reason): bem")
        #expect(withoutDetail.description == withoutDetail.reason)
    }

    // Kept deliberately exhaustive: a new case added without a reason would otherwise go unnoticed
    // until it appeared unlabelled in the committed report.
    static let oneOfEachCase: [LocaleSkip] = [
        .nonLatinDigits(numberingSystem: "arab"),
        .negativeSubpattern(pattern: "#,##0.00;-#,##0.00"),
        .noPluralRules(language: "bem"),
        .unsupportedPluralRule(language: "bem", relation: "within"),
        .unrepresentablePattern(.currencyMovesForLetterSymbols, field: .standard),
        .unrepresentablePattern(.groupingChangesForLetterSymbols, field: .standard),
        .unrepresentablePattern(.unmodelled(pattern: "a", letterSymbolPattern: "b"), field: .standard),
        .unrepresentablePattern(.currencyMovesForLetterSymbols, field: .accounting),
        .noCurrencyPlaceholder(pattern: "#,##0.00"),
        .asymmetricCurrencySpacing(before: "a", after: "b"),
        .unreadableCurrencySpacing(rule: "currencyMatch [:^S:]"),
        .unrepresentableGap("\u{2009}", symbol: "kr"),
        .multipleNameGaps([.none, .asciiSpace]),
    ]
}
