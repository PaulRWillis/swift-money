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

    @Test("Grouping off together with a non-automatic sign matches the known Foundation defect")
    func groupingOffWithSignMatchesKnownDefect() {
        let combination = FormatMatrix.combinations.first { $0.grouping == .never && $0.sign == .always() }
        #expect(combination?.isKnownFoundationGroupingDefect == true)
    }

    @Test("Grouping off together with a non-automatic separator matches the known Foundation defect")
    func groupingOffWithSeparatorMatchesKnownDefect() {
        let combination = FormatMatrix.combinations.first {
            $0.grouping == .never && $0.sign == .automatic && $0.separator == .always
        }
        #expect(combination?.isKnownFoundationGroupingDefect == true)
    }

    @Test("Grouping off alone, with every other option left automatic, does not match the known defect")
    func groupingOffAloneDoesNotMatchKnownDefect() {
        let combination = FormatMatrix.combinations.first {
            $0.grouping == .never && $0.sign == .automatic && $0.separator == .automatic
        }
        #expect(combination?.isKnownFoundationGroupingDefect == false)
    }

    @Test("Automatic grouping never matches the known defect, regardless of other options")
    func automaticGroupingNeverMatchesKnownDefect() {
        let withAutomaticGrouping = FormatMatrix.combinations.filter { $0.grouping == .automatic }
        #expect(!withAutomaticGrouping.isEmpty)
        #expect(withAutomaticGrouping.allSatisfy { !$0.isKnownFoundationGroupingDefect })
    }
}
