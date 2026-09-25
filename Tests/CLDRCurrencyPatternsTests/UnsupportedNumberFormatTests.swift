import CLDRCurrencyPatterns
import Testing

@Suite("UnsupportedNumberFormat")
struct UnsupportedNumberFormatTests {

    @Test("The one case describes itself")
    func caseDescribesItself() {
        #expect(!UnsupportedNumberFormat.nonLatinDigits(numberingSystem: "arab").description.isEmpty)
    }
}
