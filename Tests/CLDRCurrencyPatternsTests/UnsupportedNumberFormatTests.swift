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
        #expect(UnsupportedNumberFormat(standardPattern: pattern, minimumGroupingDigits: 1) == nil)
    }

    // de-CH: the affixes carry a locale's own negative arrangement, so a negative subpattern is no
    // longer refused at the number-format level. The generator reads it for a Latin-script locale, and
    // raises `.negativeSubpattern` itself where it does not, so this check does not.
    @Test("A standard pattern with a negative subpattern is representable")
    func negativeSubpatternIsRepresentable() {
        let pattern = "\u{00A4}\u{00A0}#,##0.00;\u{00A4}-#,##0.00"

        #expect(UnsupportedNumberFormat(standardPattern: pattern, minimumGroupingDigits: 1) == nil)
    }

    // A mark is zero width, so this pattern is indistinguishable from a representable one by eye. It is
    // read from the default numbering system's pattern, so a non-Latin-digit locale that marks its
    // pattern is still refused here.
    @Test("A directional mark is unrepresentable", arguments: ["\u{200F}", "\u{200E}"])
    func directionalMarkIsRefused(_ mark: String) {
        let pattern = "\(mark)#,##0.00\u{00A0}\u{00A4}"
        let unsupported = UnsupportedNumberFormat(standardPattern: pattern, minimumGroupingDigits: 1)

        #expect(unsupported == .directionalMark(pattern: pattern))
    }

    // sl: 1234 stays ungrouped, 12345 becomes 12.345. The engine groups by size alone.
    @Test("A grouping threshold above one is unrepresentable")
    func groupingThresholdIsRefused() {
        let unsupported = UnsupportedNumberFormat(
            standardPattern: "#,##0.00\u{00A0}\u{00A4}",
            minimumGroupingDigits: 2
        )

        #expect(unsupported == .groupingThreshold(minimumDigits: 2))
    }

    @Test("Each case describes itself")
    func casesDescribeThemselves() {
        let descriptions = [
            UnsupportedNumberFormat.nonLatinDigits(numberingSystem: "arab"),
            .negativeSubpattern(pattern: "a;b"),
            .directionalMark(pattern: "a"),
            .groupingThreshold(minimumDigits: 2),
        ].map(\.description)

        #expect(descriptions.allSatisfy { !$0.isEmpty })
        #expect(Set(descriptions).count == descriptions.count)
    }
}
