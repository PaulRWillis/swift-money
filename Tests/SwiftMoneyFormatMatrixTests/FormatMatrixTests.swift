import Foundation
import SwiftMoneyCore
import SwiftMoneyFormatMatrix
import SwiftMoneyLocalization
import Testing

@Suite("FormatMatrix")
struct FormatMatrixTests {

    @Test("The option cross has one entry per presentation, sign, grouping, separator and precision combination")
    func combinationCount() {
        let expected = FormatMatrix.presentations.count * FormatMatrix.signs.count
            * FormatMatrix.groupings.count * FormatMatrix.separators.count * FormatMatrix.precisions.count

        #expect(FormatMatrix.combinations.count == expected)
        #expect(expected == 256)
    }

    @Test("Every combination has a distinct id")
    func combinationIDsAreUnique() {
        let ids = Set(FormatMatrix.combinations.map(\.id))
        #expect(ids.count == FormatMatrix.combinations.count)
    }

    @Test("The covered locales are those the CLDR blob ships")
    func coveredLocales() {
        #expect(!FormatMatrix.coveredLocaleIDs.isEmpty)
        #expect(FormatMatrix.coveredLocaleIDs == MoneyLocalization.coveredLocaleIdentifiers)
    }

    @Test("The option-cross currencies span 0, 2 and 3 decimal places")
    func optionCurrenciesSpanScales() {
        #expect(FormatMatrix.optionCurrencies.map(\.unitScale.decimalPlaces) == [0, 2, 3])
    }

    @Test("A locale's shard is within the count and the same every time", arguments: FormatMatrix.coveredLocaleIDs)
    func shardIsInRangeAndDeterministic(_ localeID: String) {
        let count = 4
        let shard = FormatMatrix.shard(ofLocale: localeID, count: count)

        #expect((0 ..< count).contains(shard))
        #expect(FormatMatrix.shard(ofLocale: localeID, count: count) == shard)
    }

    @Test("The shards partition the golden locales with nothing lost or shared")
    func shardsPartitionTheGoldenLocales() {
        let count = 3
        let shards = (0 ..< count).map { FormatMatrix.localeIDs(inShard: $0, of: count) }

        #expect(shards.flatMap { $0 }.sorted() == FormatMatrix.goldenLocaleIDs.sorted())
        #expect(Set(shards.flatMap { $0 }).count == FormatMatrix.goldenLocaleIDs.count)
    }

    @Test("A count of one means no sharding")
    func countOfOneReturnsEveryLocale() {
        #expect(FormatMatrix.localeIDs(inShard: 0, of: 1) == FormatMatrix.goldenLocaleIDs)
    }

    @Test("A requested subset selects the covered locales and reports the rest as unknown")
    func requestedSubsetSplitsCoveredFromUnknown() {
        let covered = Array(FormatMatrix.coveredLocaleIDs.prefix(2))
        let resolved = FormatMatrix.coveredLocales(among: covered + ["zz-ZZ"])

        #expect(resolved.selected == covered)
        #expect(resolved.unknown == ["zz-ZZ"])
    }

    @Test("Selected locales follow the covered set's order, not the requested order")
    func selectedFollowsCoveredOrder() {
        let covered = Array(FormatMatrix.coveredLocaleIDs.prefix(2))
        let resolved = FormatMatrix.coveredLocales(among: [covered[1], covered[0]])

        #expect(resolved.selected == covered)
    }

    @Test("A request of only unknown locales selects none and reports them all")
    func allUnknownSelectsNone() {
        let resolved = FormatMatrix.coveredLocales(among: ["zz-ZZ", "not-a-locale"])

        #expect(resolved.selected.isEmpty)
        #expect(resolved.unknown == ["zz-ZZ", "not-a-locale"])
    }

    @Test("An empty request selects and reports nothing")
    func emptyRequestSelectsNothing() {
        let resolved = FormatMatrix.coveredLocales(among: [])

        #expect(resolved.selected.isEmpty)
        #expect(resolved.unknown.isEmpty)
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

    // A cell ICU would have to render is one neither the golden hash nor the deviation report can
    // use: ICU's text differs by platform, and comparing it against itself proves nothing.
    @Test("A presentation that needs no data is always covered", arguments: [
        FormatMatrix.Config.Presentation.standard, .isoCode, .narrow,
    ])
    func symbolPresentationsAreAlwaysCovered(_ presentation: FormatMatrix.Config.Presentation) {
        #expect(FormatMatrix.isEngineCovered(.gbp, localeID: "en_GB", presentation: presentation))
    }

    @Test("A full name is covered only where CLDR names the currency")
    func fullNamesAreCoveredWhereNamed() throws {
        let unnamed = try #require(CurrencyCode(string: "XAD").flatMap(Currency.init(iso:)))

        #expect(FormatMatrix.isEngineCovered(.gbp, localeID: "en_GB", presentation: .fullName))
        #expect(!FormatMatrix.isEngineCovered(unnamed, localeID: "en_GB", presentation: .fullName))
    }

    @Test("No cell is covered in a locale the data does not carry")
    func uncoveredLocaleCoversNothing() {
        #expect(!FormatMatrix.isEngineCovered(.gbp, localeID: "zz_ZZ", presentation: .fullName))
    }

    @Test("A full name at an explicit precision is not covered, since it renders through ICU")
    func fullNameAtExplicitPrecisionIsNotCovered() throws {
        let combination = try #require(
            FormatMatrix.combinations.first { $0.presentation == .fullName && $0.precision == .fractionLength(2) }
        )
        #expect(!FormatMatrix.isEngineCovered(.gbp, localeID: "en_GB", combination: combination))
    }

    @Test("A full name at the default precision is covered only where CLDR names the currency")
    func fullNameAtDefaultPrecisionFollowsTheName() throws {
        let combination = try #require(
            FormatMatrix.combinations.first { $0.presentation == .fullName && $0.precision == nil }
        )
        let unnamed = try #require(CurrencyCode(string: "XAD").flatMap(Currency.init(iso:)))

        #expect(FormatMatrix.isEngineCovered(.gbp, localeID: "en_GB", combination: combination))
        #expect(!FormatMatrix.isEngineCovered(unnamed, localeID: "en_GB", combination: combination))
    }

    @Test("A symbol presentation stays covered even at an explicit precision")
    func symbolPresentationAtExplicitPrecisionIsCovered() throws {
        let combination = try #require(
            FormatMatrix.combinations.first { $0.presentation == .standard && $0.precision == .fractionLength(2) }
        )
        #expect(FormatMatrix.isEngineCovered(.gbp, localeID: "en_GB", combination: combination))
    }
}
