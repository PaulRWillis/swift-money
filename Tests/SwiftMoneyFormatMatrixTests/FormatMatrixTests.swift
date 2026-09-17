import SwiftMoneyCore
import SwiftMoneyFormatMatrix
import Testing

@Suite("FormatMatrix")
struct FormatMatrixTests {

    @Test("The option cross has one entry per presentation, sign, grouping and separator combination")
    func combinationCount() {
        #expect(FormatMatrix.combinations.count == 48)
    }

    @Test("Every combination has a distinct id")
    func combinationIDsAreUnique() {
        let ids = Set(FormatMatrix.combinations.map(\.id))
        #expect(ids.count == FormatMatrix.combinations.count)
    }

    @Test("The covered locales are the five the CLDR data ships")
    func coveredLocales() {
        #expect(FormatMatrix.coveredLocaleIDs == ["en_US", "en_GB", "de_DE", "fr_FR", "ja_JP"])
    }

    @Test("The option-cross currencies span 0, 2 and 3 decimal places")
    func optionCurrenciesSpanScales() {
        #expect(FormatMatrix.optionCurrencies.map(\.unitScale.decimalPlaces) == [0, 2, 3])
    }
}
