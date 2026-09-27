import CLDRCurrencyPatterns
import Testing

// Proves the predicate a locale's letter-adjacent lift is guarded by: a letter-adjacent symbol always
// renders through the *plain* pattern's column, never through its own letter-adjacent pattern's gap
// directly, so the two can genuinely disagree without anything being unmodelled about their side or
// grouping — the shape `UnsupportedPattern`'s own side/grouping/gap check cannot see, because a
// gap-only difference there is exactly the case it treats as already representable.
@Suite("Letter-Adjacent Gap Mismatch Tests")
struct LetterAdjacentGapMismatchTests {

    @Test("A letter-adjacent pattern's own literal gap, when the plain pattern has none of its own, matches the currencySpacing insertion")
    func emptyPlainGapMatchesInsertion() {
        // khq-shaped: accounting's own gap is empty, so a letter-adjacent symbol renders through
        // CLDR's `currencySpacing` insertion for its boundary — which the letter-adjacent pattern's
        // own literal gap happens to equal here, so nothing renders wrong.
        let mismatches = letterAdjacentGapWouldMismatch(
            plainPositive: "#,##0.00¤", plainSide: .trailing,
            letterAdjacentPositive: "¤\u{00A0}#,##0.00", letterAdjacentSide: .leading,
            insertBetween: "\u{00A0}"
        )
        #expect(mismatches == false)
    }

    @Test("A letter-adjacent pattern's own literal gap, when it differs from the plain pattern's non-empty one, mismatches")
    func nonEmptyPlainGapMismatch() {
        // en-ZA-shaped: `accounting` carries no gap of its own; `accounting-alphaNextToNumber` carries
        // a non-breaking-space gap, same side and grouping as `accounting` — a shape `UnsupportedPattern`
        // treats as already representable (side and grouping agree), but the render cannot carry the
        // letter-adjacent pattern's own gap, only the plain column's.
        let mismatches = letterAdjacentGapWouldMismatch(
            plainPositive: "¤#,##0.00", plainSide: .leading,
            letterAdjacentPositive: "¤\u{00A0}#,##0.00", letterAdjacentSide: .leading,
            insertBetween: " "
        )
        #expect(mismatches == true)
    }

    @Test("Identical gaps at the same side never mismatch")
    func identicalGapsNeverMismatch() {
        let mismatches = letterAdjacentGapWouldMismatch(
            plainPositive: "¤\u{00A0}#,##0.00", plainSide: .leading,
            letterAdjacentPositive: "¤\u{00A0}#,##0.00", letterAdjacentSide: .leading,
            insertBetween: " "
        )
        #expect(mismatches == false)
    }

    @Test("A pattern with no currency placeholder or no digit reports no verdict, not a false match")
    func noCurrencyPlaceholderReportsNoVerdict() {
        let missingPlaceholder = letterAdjacentGapWouldMismatch(
            plainPositive: "#,##0.00", plainSide: .leading,
            letterAdjacentPositive: "¤#,##0.00", letterAdjacentSide: .leading,
            insertBetween: " "
        )
        #expect(missingPlaceholder == nil)

        let noDigit = letterAdjacentGapWouldMismatch(
            plainPositive: "¤#,##0.00", plainSide: .leading,
            letterAdjacentPositive: "¤", letterAdjacentSide: .leading,
            insertBetween: " "
        )
        #expect(noDigit == nil)
    }

    @Test("patternGap reads the text on the currency's own side, leading or trailing")
    func patternGapReadsTheRightSide() {
        #expect(patternGap(ofStrippedPositive: "¤\u{00A0}#,##0.00", side: .leading) == "\u{00A0}")
        #expect(patternGap(ofStrippedPositive: "#,##0.00\u{00A0}¤", side: .trailing) == "\u{00A0}")
        #expect(patternGap(ofStrippedPositive: "¤#,##0.00", side: .leading) == "")
    }
}
