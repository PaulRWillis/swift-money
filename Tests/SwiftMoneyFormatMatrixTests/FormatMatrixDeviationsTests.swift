import SwiftMoneyCore
import SwiftMoneyFormatMatrix
import Testing

// Fixture renderers pin the predicate/cardinality without the cost of the real matrix.
// `icuFormatted`/`engineFormatted` get a smoke test instead, since their output is real ICU text.
@Suite("FormatMatrix deviations")
struct FormatMatrixDeviationsTests {
    static let currencies: [Currency] = [.gbp]
    static let localeIDs = ["en_GB"]
    static let combinations = Array(FormatMatrix.combinations.prefix(2))
    static let amounts: [Int64] = [0, 1]

    @Test("Identical renderers produce no deviations")
    func noDeviationsWhenEqual() {
        let found = FormatMatrix.deviations(
            currencies: Self.currencies, localeIDs: Self.localeIDs,
            combinations: Self.combinations, amounts: Self.amounts,
            engine: { _, _, _, amount in "same-\(amount)" },
            icu: { _, _, _, amount in "same-\(amount)" }
        )
        #expect(found.isEmpty)
    }

    @Test("A differing renderer produces exactly one deviation per differing cell")
    func oneDeviationPerDifference() {
        let found = FormatMatrix.deviations(
            currencies: Self.currencies, localeIDs: Self.localeIDs,
            combinations: Self.combinations, amounts: Self.amounts,
            engine: { _, _, _, amount in "engine-\(amount)" },
            icu: { _, _, _, amount in "icu-\(amount)" }
        )
        // 1 currency x 1 locale x 2 combinations x 2 amounts, every cell differing.
        #expect(found.count == 4)
    }

    @Test("A deviation carries the cell it was found at")
    func deviationCarriesCellIdentity() {
        let combination = Self.combinations[0]
        let found = FormatMatrix.deviations(
            currencies: Self.currencies, localeIDs: Self.localeIDs,
            combinations: [combination], amounts: [42],
            engine: { _, _, _, _ in "E" },
            icu: { _, _, _, _ in "I" }
        )
        #expect(found == [
            FormatMatrix.Deviation(
                localeID: "en_GB", currencyCode: "GBP", combinationID: combination.id,
                amount: 42, engine: "E", icu: "I",
                isKnownFoundationGroupingDefect: combination.isKnownFoundationGroupingDefect
            ),
        ])
    }

    @Test("A deviation's known-defect flag matches its combination's classification")
    func deviationFlagMatchesCombinationClassification() {
        guard
            let buggy = FormatMatrix.combinations.first(where: { $0.grouping == .never && $0.sign == .always() }),
            let safe = FormatMatrix.combinations.first(where: { $0.grouping == .automatic })
        else {
            Issue.record("Expected both a grouping-off/always-sign and an automatic-grouping combination")
            return
        }

        let found = FormatMatrix.deviations(
            currencies: Self.currencies, localeIDs: Self.localeIDs,
            combinations: [buggy, safe], amounts: [0],
            engine: { _, _, _, _ in "E" }, icu: { _, _, _, _ in "I" }
        )

        #expect(found.first { $0.combinationID == buggy.id }?.isKnownFoundationGroupingDefect == true)
        #expect(found.first { $0.combinationID == safe.id }?.isKnownFoundationGroupingDefect == false)
    }

    @Test("The real entry point, with no fixture renderers, finds nothing wrong on a covered case")
    func realEntryPointAgreesOnACoveredCase() {
        let found = FormatMatrix.deviations(
            currencies: Self.currencies, localeIDs: Self.localeIDs,
            combinations: [FormatMatrix.combinations[0]], amounts: [4_99]
        )
        #expect(found.isEmpty)
    }

    @Test("The real engine and ICU renderers produce matching, non-empty output for a covered case")
    func realRenderersAgreeOnACoveredCase() {
        let money = Money(minorUnits: 4_99, currency: .gbp)
        let combination = FormatMatrix.combinations[0]
        let engine = FormatMatrix.engineFormatted(money, localeID: "en_GB", combination: combination)
        let icu = FormatMatrix.icuFormatted(money, localeID: "en_GB", combination: combination)
        #expect(engine.contains("4.99"))
        #expect(icu.contains("4.99"))
    }

    // One run's output is compared against another's by sorting the lines and diffing them, so a
    // line has to name its own cell in full and start with the fields worth grouping by.
    @Test("A deviation reports as one line naming its own cell")
    func deviationReportsAsOneLine() {
        let deviation = FormatMatrix.Deviation(
            localeID: "ja_JP", currencyCode: "JPY",
            combinationID: "standard|automatic|automatic|automatic", amount: 100,
            engine: "\u{FFE5}100", icu: "\u{00A5}100",
            isKnownFoundationGroupingDefect: false
        )

        #expect(deviation.reportLine == "ja_JP JPY standard|automatic|automatic|automatic 100: engine '\u{FFE5}100' vs ICU '\u{00A5}100'")
        #expect(!deviation.reportLine.contains("\n"))
    }

    // Renderers that always disagree still produce nothing here, because the cell is one ICU would
    // have rendered on both sides.
    @Test("A cell the data cannot render is not compared at all")
    func uncoveredCellsAreSkipped() throws {
        let unnamed = try #require(CurrencyCode(string: "XAD").flatMap(Currency.init(iso:)))
        let fullNames = FormatMatrix.combinations.filter { $0.presentation == .fullName }

        let found = FormatMatrix.deviations(
            currencies: [unnamed], localeIDs: Self.localeIDs,
            combinations: fullNames, amounts: Self.amounts,
            engine: { _, _, _, _ in "engine" },
            icu: { _, _, _, _ in "icu" }
        )

        #expect(!fullNames.isEmpty)
        #expect(found.isEmpty)
    }
}
