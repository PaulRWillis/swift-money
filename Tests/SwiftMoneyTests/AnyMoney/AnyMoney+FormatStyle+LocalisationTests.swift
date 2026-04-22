import Foundation
import SwiftMoney
import Testing

/// Broad localisation coverage for `AnyMoney.FormatStyle`.
///
/// ## Fidelity approach
///
/// `AnyMoney.FormatStyle` carries its own `minimalQuantisation` at runtime and
/// applies the same scale formula as `Money<C>.FormatStyle`. These tests
/// compare `AnyMoney.FormatStyle` output against `Money<C>.FormatStyle` output
/// (which is independently verified correct by `Money+FormatStyle+LocalisationTests`)
/// confirming that the two implementations remain in parity across all locales.
@Suite("AnyMoney – FormatStyle – Localisation")
struct AnyMoney_FormatStyle_LocalisationTests {

    // MARK: - Fidelity: GBP (minQ = 100)

    @Test(
        "AnyMoney<GBP> format matches Money<GBP>.FormatStyle across locales",
        arguments: localizationTestLocales
    )
    func gbpFidelity(locale: Locale) {
        let money = Money<GBP>(minorUnits: 123_456)
        let typed = Money<GBP>.FormatStyle(locale: locale).format(money)
        let any   = money.erased.formatted(AnyMoney.FormatStyle(locale: locale))
        #expect(any == typed, "Locale \(locale.identifier): AnyMoney got \(any.debugDescription), Money<GBP> got \(typed.debugDescription)")
    }

    // MARK: - Fidelity: JPY (minQ = 1)

    @Test(
        "AnyMoney<JPY> format matches Money<JPY>.FormatStyle across locales",
        arguments: localizationTestLocales
    )
    func jpyFidelity(locale: Locale) {
        let money = Money<JPY>(minorUnits: 12_345)
        let typed = Money<JPY>.FormatStyle(locale: locale).format(money)
        let any   = money.erased.formatted(AnyMoney.FormatStyle(locale: locale))
        #expect(any == typed, "Locale \(locale.identifier): AnyMoney got \(any.debugDescription), Money<JPY> got \(typed.debugDescription)")
    }

    // MARK: - Fidelity: KWD (minQ = 1000)

    @Test(
        "AnyMoney<TestKWD> format matches Money<TestKWD>.FormatStyle across locales (3-decimal currency)",
        arguments: localizationTestLocales
    )
    func kwdFidelity(locale: Locale) {
        let money = Money<TestKWD>(minorUnits: 1_234_567)
        let typed = Money<TestKWD>.FormatStyle(locale: locale).format(money)
        let any   = money.erased.formatted(AnyMoney.FormatStyle(locale: locale))
        #expect(any == typed, "Locale \(locale.identifier): AnyMoney got \(any.debugDescription), Money<TestKWD> got \(typed.debugDescription)")
    }

    // MARK: - Structural invariant: isoCode presentation

    @Test(
        "AnyMoney presentation(.isoCode) always contains the ISO currency code",
        arguments: localizationTestLocales
    )
    func isoCodeContainsCurrencyCode(locale: Locale) {
        let style = AnyMoney.FormatStyle(locale: locale).presentation(.isoCode)
        let result = Money<GBP>(minorUnits: 12_345).erased.formatted(style)
        #expect(result.contains("GBP"), "Locale \(locale.identifier): \(result.debugDescription) should contain \"GBP\"")
    }

    // MARK: - Structural invariant: grouping(.never)

    @Test(
        "AnyMoney grouping(.never) output is no longer than grouping(.automatic)",
        arguments: localizationTestLocales
    )
    func groupingNeverNoLongerThanAutomatic(locale: Locale) {
        let amount = Money<GBP>(minorUnits: 1_234_567_800).erased
        let withGrouping    = amount.formatted(AnyMoney.FormatStyle(locale: locale).grouping(.automatic))
        let withoutGrouping = amount.formatted(AnyMoney.FormatStyle(locale: locale).grouping(.never))
        #expect(
            withoutGrouping.count <= withGrouping.count,
            "Locale \(locale.identifier): grouping(.never) (\(withoutGrouping.count) chars) should be ≤ grouping(.automatic) (\(withGrouping.count) chars)"
        )
    }
}
