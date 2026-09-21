import CLDRCurrencyPatterns
import Testing

// Whether a locale's pair of currency patterns is one the generated tables can represent. Every pattern
// below is a real one from CLDR 48.2, named by the locale it came from, since the point of the check is
// to recognise the shapes CLDR actually publishes.
@Suite("Unsupported Pattern Tests")
struct UnsupportedPatternTests {

    // What the shipped locales look like: either no variant at all, one identical to the pattern, or one
    // that differs only by the gap beside the currency, which is resolved per symbol anyway.
    @Test("A pair that differs by no more than spacing is representable", arguments: [
        ("¤#,##0.00", "¤\u{00A0}#,##0.00"),          // en, en-GB, ja, si
        ("#,##0.00\u{00A0}¤", "#,##0.00\u{00A0}¤"),  // de, fr, ro
        ("¤\u{00A0}#,##0.00", "¤\u{00A0}#,##0.00"),  // sw
    ])
    func spacingOnlyIsRepresentable(_ pattern: String, _ letterSymbolPattern: String) {
        #expect(UnsupportedPattern(pattern: pattern, letterSymbolPattern: letterSymbolPattern) == nil)
    }

    @Test("A locale publishing no variant is representable")
    func noVariantIsRepresentable() {
        #expect(UnsupportedPattern(pattern: "¤#,##0.00", letterSymbolPattern: nil) == nil)
    }

    // khq, kab, twq, dje and 23 others: "1 234,00 F" but "USD 1 234,00".
    @Test("A currency that changes side is refused")
    func currencyMoving() {
        #expect(
            UnsupportedPattern(pattern: "#,##0.00¤", letterSymbolPattern: "¤\u{00A0}#,##0.00")
                == .currencyMovesForLetterSymbols
        )
    }

    // dz and sa drop Indian grouping when the currency is spelled out; dv adds it.
    @Test("Grouping that changes is refused")
    func groupingChanging() {
        #expect(
            UnsupportedPattern(pattern: "¤#,##,##0.00", letterSymbolPattern: "¤\u{00A0}#,##0.00")
                == .groupingChangesForLetterSymbols
        )
    }

    // bqi adds a left-to-right mark, which is not spacing and not a rearrangement either.
    @Test("A difference that is neither side nor grouping is refused as unmodelled")
    func unmodelledDifference() {
        let unsupported = UnsupportedPattern(
            pattern: "¤\u{00A0}#,##0.00",
            letterSymbolPattern: "\u{200E}¤\u{00A0}#,##0.00"
        )

        #expect(unsupported == .unmodelled(
            pattern: "¤\u{00A0}#,##0.00",
            letterSymbolPattern: "\u{200E}¤\u{00A0}#,##0.00"
        ))
    }

    // nn, no, nb and nb-SJ publish a negative subpattern the variant drops.
    @Test("A variant that drops the negative subpattern is refused")
    func droppedNegativeSubpattern() {
        let standard = "#,##0.00\u{00A0}¤;-#,##0.00\u{00A0}¤"
        let unsupported = UnsupportedPattern(pattern: standard, letterSymbolPattern: "#,##0.00\u{00A0}¤")

        #expect(unsupported == .unmodelled(pattern: standard, letterSymbolPattern: "#,##0.00\u{00A0}¤"))
    }

    // The report has to say enough to act on, and for a difference this tool cannot name, that means
    // showing both patterns.
    @Test("An unmodelled difference describes both patterns")
    func unmodelledDescribesBoth() {
        let unsupported = UnsupportedPattern.unmodelled(pattern: "¤0.00", letterSymbolPattern: "¤ 0.00")

        #expect(unsupported.description.contains("¤0.00"))
        #expect(unsupported.description.contains("¤ 0.00"))
    }
}
