import CLDRCurrencyPatterns
import Testing

@Suite("UnsupportedNumberFormat")
struct UnsupportedNumberFormatTests {

    // Real CLDR 48.2 patterns, so the check is pinned to the data rather than to invented strings.
    @Test(
        "A Latin-digit pattern with one arrangement is representable",
        arguments: [
            "\u{00A4}#,##0.00",              // en
            "#,##0.00\u{00A0}\u{00A4}",      // de
            "\u{00A4}\u{00A0}#,##0.00",      // pt
            "#,##,##0.00\u{00A4}",           // Indian grouping
            "\u{00A4}#,##0.00",              // ja
        ]
    )
    func representablePatterns(_ pattern: String) {
        #expect(UnsupportedNumberFormat(standardPattern: pattern, defaultNumberingSystem: "latn") == nil)
    }

    @Test("A numbering system other than latn is unrepresentable whatever the pattern is")
    func nonLatinDigitsAreRefused() {
        let unsupported = UnsupportedNumberFormat(
            standardPattern: "\u{00A4}#,##0.00",
            defaultNumberingSystem: "arab"
        )

        #expect(unsupported == .nonLatinDigits(numberingSystem: "arab"))
    }

    // de-CH: the tables hold one arrangement plus a leading sign, so a locale that writes its own
    // negative would come out with the minus in the wrong place.
    @Test("A standard pattern with a negative subpattern is unrepresentable")
    func negativeSubpatternIsRefused() {
        let pattern = "\u{00A4}\u{00A0}#,##0.00;\u{00A4}-#,##0.00"
        let unsupported = UnsupportedNumberFormat(standardPattern: pattern, defaultNumberingSystem: "latn")

        #expect(unsupported == .negativeSubpattern(pattern: pattern))
    }

    // A mark is zero width, so this pattern is indistinguishable from a representable one by eye.
    @Test("A directional mark is unrepresentable", arguments: ["\u{200F}", "\u{200E}"])
    func directionalMarkIsRefused(_ mark: String) {
        let pattern = "\(mark)#,##0.00\u{00A0}\u{00A4}"
        let unsupported = UnsupportedNumberFormat(standardPattern: pattern, defaultNumberingSystem: "latn")

        #expect(unsupported == .directionalMark(pattern: pattern))
    }

    // ar: both reasons at once. The digits are reported, because a locale recovering its pattern
    // would still be unreadable in the wrong digits.
    @Test("Digits are reported ahead of the pattern when both are unrepresentable")
    func digitsOutrankThePattern() {
        let unsupported = UnsupportedNumberFormat(
            standardPattern: "\u{200F}#,##0.00\u{00A0}\u{00A4}",
            defaultNumberingSystem: "arab"
        )

        #expect(unsupported == .nonLatinDigits(numberingSystem: "arab"))
    }

    @Test("Each case describes itself")
    func casesDescribeThemselves() {
        let descriptions = [
            UnsupportedNumberFormat.nonLatinDigits(numberingSystem: "arab"),
            .negativeSubpattern(pattern: "a;b"),
            .directionalMark(pattern: "a"),
        ].map(\.description)

        #expect(descriptions.allSatisfy { !$0.isEmpty })
        #expect(Set(descriptions).count == descriptions.count)
    }
}
