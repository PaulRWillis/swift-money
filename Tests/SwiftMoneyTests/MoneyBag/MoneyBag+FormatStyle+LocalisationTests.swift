import Foundation
import SwiftMoney
import Testing

/// Broad localisation coverage for `MoneyBag.formatted(locale:)`.
///
/// ## Fidelity approach
///
/// `MoneyBag.formatted(locale:)` delegates to `AnyMoney.FormatStyle(locale:)` and
/// joins the results with `", "` in currency-code sort order. These tests
/// verify that the `locale` parameter is correctly threaded through for each
/// entry across all locales, by independently reconstructing the expected string
/// from `MoneyBag.breakdown` and comparing.
@Suite("MoneyBag – FormatStyle – Localisation")
struct MoneyBag_FormatStyle_LocalisationTests {

    // MARK: - Helpers

    /// A multi-currency bag exercising three different minimalQuantisation values.
    private func makeTestBag() -> MoneyBag {
        MoneyBag()
            .adding(Money<GBP>(minorUnits: 123_456))    // minQ = 100
            .adding(Money<JPY>(minorUnits: 12_345))     // minQ = 1
            .adding(Money<TestKWD>(minorUnits: 1_234_567)) // minQ = 1000
    }

    // MARK: - Fidelity: formatted(locale:) matches manual AnyMoney join

    @Test(
        "formatted(locale:) matches manual AnyMoney.FormatStyle join across locales",
        arguments: localizationTestLocales
    )
    func formattedMatchesManualJoin(locale: Locale) {
        let bag = makeTestBag()
        let style = AnyMoney.FormatStyle(locale: locale)
        let expected = bag.breakdown.map { $0.formatted(style) }.joined(separator: ", ")
        let result = bag.formatted(locale: locale)
        #expect(result == expected, "Locale \(locale.identifier): got \(result.debugDescription), want \(expected.debugDescription)")
    }

    // MARK: - Structural invariant: currency-code sort order is locale-independent

    @Test(
        "formatted(locale:) entries appear in currency-code sort order for all locales",
        arguments: localizationTestLocales
    )
    func formattedEntriesAreSortedForAllLocales(locale: Locale) {
        let bag = makeTestBag()
        let result = bag.formatted(locale: locale)
        // GBP < JPY < KWD lexicographically, so GBP entry must appear before JPY which appears before KWD.
        let gbpFormatted = Money<GBP>(minorUnits: 123_456).erased.formatted(AnyMoney.FormatStyle(locale: locale))
        let jpyFormatted = Money<JPY>(minorUnits: 12_345).erased.formatted(AnyMoney.FormatStyle(locale: locale))
        let kwdFormatted = Money<TestKWD>(minorUnits: 1_234_567).erased.formatted(AnyMoney.FormatStyle(locale: locale))
        let gbpRange = try! #require(result.range(of: gbpFormatted), "Locale \(locale.identifier): GBP entry not found in \(result.debugDescription)")
        let jpyRange = try! #require(result.range(of: jpyFormatted), "Locale \(locale.identifier): JPY entry not found in \(result.debugDescription)")
        let kwdRange = try! #require(result.range(of: kwdFormatted), "Locale \(locale.identifier): KWD entry not found in \(result.debugDescription)")
        #expect(gbpRange.lowerBound < jpyRange.lowerBound, "Locale \(locale.identifier): GBP should appear before JPY")
        #expect(jpyRange.lowerBound < kwdRange.lowerBound, "Locale \(locale.identifier): JPY should appear before KWD")
    }
}
