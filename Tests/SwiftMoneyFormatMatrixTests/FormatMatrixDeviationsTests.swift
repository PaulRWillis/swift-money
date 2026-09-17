import SwiftMoneyCore
import SwiftMoneyFormatMatrix
import Testing

// The predicate and cardinality are pinned with fixture renderers rather than the real matrix: the
// real one is 165 currencies x 5 locales x 48 combinations x 5 amounts of actual ICU calls, which
// belongs in the report executable's own run, not in every `swift test`. `icuFormatted`/
// `engineFormatted` get a smoke test instead of a pinned literal, since their output is real,
// platform-dependent ICU text.
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
}
