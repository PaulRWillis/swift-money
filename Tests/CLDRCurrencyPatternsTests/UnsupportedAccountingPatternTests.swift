import CLDRCurrencyPatterns
import Testing

@Suite("UnsupportedAccountingPattern")
struct UnsupportedAccountingPatternTests {

    // Real CLDR 48.2 pairs. Parentheses are the one thing an accounting pattern may add, so a pair
    // that differs only by them is representable.
    @Test(
        "An accounting pattern that only adds parentheses is representable",
        arguments: [
            ("\u{00A4}#,##0.00", "\u{00A4}#,##0.00;(\u{00A4}#,##0.00)"),        // en
            ("#,##0.00\u{00A0}\u{00A4}", "#,##0.00\u{00A0}\u{00A4}"),            // de, identical
            ("\u{00A4}\u{00A0}#,##0.00", "\u{00A4}\u{00A0}#,##0.00;(\u{00A4}\u{00A0}#,##0.00)"),
        ]
    )
    func representablePairs(_ pair: (standard: String, accounting: String)) {
        #expect(UnsupportedAccountingPattern(standard: pair.standard, accounting: pair.accounting) == nil)
    }

    // nb: the currency trails the digits normally and leads them for accounting.
    @Test("A currency that changes side for accounting is unrepresentable")
    func sideChangeIsRefused() {
        let unsupported = UnsupportedAccountingPattern(
            standard: "#,##0.00\u{00A0}\u{00A4};-#,##0.00\u{00A0}\u{00A4}",
            accounting: "\u{00A4}\u{00A0}#,##0.00;(\u{00A4}\u{00A0}#,##0.00)"
        )

        #expect(unsupported == .currencyMovesForAccounting)
    }

    // ta and en-IN: Indian grouping normally, Western for accounting. The record holds one grouping.
    @Test("Grouping that changes for accounting is unrepresentable")
    func groupingChangeIsRefused() {
        let unsupported = UnsupportedAccountingPattern(
            standard: "\u{00A4}#,##,##0.00",
            accounting: "\u{00A4}#,##0.00;(\u{00A4}#,##0.00)"
        )

        #expect(unsupported == .groupingChangesForAccounting)
    }

    // pa: no gap after the currency normally, a no-break space for accounting.
    @Test("A gap that changes for accounting is unrepresentable")
    func spacingChangeIsRefused() {
        let unsupported = UnsupportedAccountingPattern(
            standard: "\u{00A4}#,##,##0.00",
            accounting: "\u{00A4}\u{00A0}#,##0.00"
        )

        // Grouping is read first, and this pair changes that too.
        #expect(unsupported == .groupingChangesForAccounting)

        let spacingOnly = UnsupportedAccountingPattern(
            standard: "\u{00A4}#,##0.00",
            accounting: "\u{00A4}\u{00A0}#,##0.00"
        )

        #expect(spacingOnly == .spacingChangesForAccounting)
    }

    @Test("Each case describes itself")
    func casesDescribeThemselves() {
        let descriptions = [
            UnsupportedAccountingPattern.currencyMovesForAccounting,
            .groupingChangesForAccounting,
            .spacingChangesForAccounting,
        ].map(\.description)

        #expect(descriptions.allSatisfy { !$0.isEmpty })
        #expect(Set(descriptions).count == descriptions.count)
    }
}
