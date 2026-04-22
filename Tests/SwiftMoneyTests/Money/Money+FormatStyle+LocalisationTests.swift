import Foundation
import SwiftMoney
import Testing

/// Broad localisation coverage for `Money.FormatStyle`.
///
/// ## Fidelity approach
///
/// Rather than hard-coding locale-specific strings (which would break when
/// ICU/Foundation output changes between OS versions), each fidelity test
/// asserts that `Money<C>.FormatStyle` produces **exactly the same string as
/// `IntegerFormatStyle<Int64>.Currency` built with identical parameters**.
/// This proves our scale math and modifier forwarding are correct while
/// remaining future-proof across OS/ICU updates.
///
/// ## Structural invariants
///
/// Separate tests assert locale-independent *properties* of the output
/// (e.g. the ISO code is always present in `.isoCode` presentation) without
/// comparing to hardcoded strings.
///
/// ## Divergence handling
///
/// If a specific locale+OS combination produces a reproducible divergence from
/// the Foundation reference, it is removed from the general parameter list and
/// isolated in its own `withKnownIssue { ... }` test so it surfaces
/// automatically when a future OS version fixes the underlying issue.
@Suite("Money - FormatStyle - Localisation")
struct Money_FormatStyle_LocalisationTests {

    // MARK: - Fidelity: GBP (minQ = 100, scale = 0.01)

    @Test(
        "Money<GBP> format matches Foundation reference across locales",
        arguments: localizationTestLocales
    )
    func gbpFidelity(locale: Locale) {
        let minorUnits: Int64 = 123_456
        let money = Money<GBP>(minorUnits: minorUnits)

        let ours = Money<GBP>.FormatStyle(locale: locale).format(money)

        let reference = minorUnits.formatted(
            IntegerFormatStyle<Int64>.Currency(code: "GBP", locale: locale)
                .presentation(.standard)
                .scale(1.0 / 100.0)
        )

        #expect(ours == reference, "Locale \(locale.identifier): got \(ours.debugDescription), want \(reference.debugDescription)")
    }

    // MARK: - Fidelity: JPY (minQ = 1, scale = 1.0)

    @Test(
        "Money<JPY> format matches Foundation reference across locales",
        arguments: localizationTestLocales
    )
    func jpyFidelity(locale: Locale) {
        let minorUnits: Int64 = 12_345
        let money = Money<JPY>(minorUnits: minorUnits)

        let ours = Money<JPY>.FormatStyle(locale: locale).format(money)

        let reference = minorUnits.formatted(
            IntegerFormatStyle<Int64>.Currency(code: "JPY", locale: locale)
                .presentation(.standard)
                .scale(1.0 / 1.0)
        )

        #expect(ours == reference, "Locale \(locale.identifier): got \(ours.debugDescription), want \(reference.debugDescription)")
    }

    // MARK: - Fidelity: KWD (minQ = 1000, scale = 0.001)

    @Test(
        "Money<TestKWD> format matches Foundation reference across locales (3-decimal currency)",
        arguments: localizationTestLocales
    )
    func kwdFidelity(locale: Locale) {
        let minorUnits: Int64 = 1_234_567
        let money = Money<TestKWD>(minorUnits: minorUnits)

        let ours = Money<TestKWD>.FormatStyle(locale: locale).format(money)

        let reference = minorUnits.formatted(
            IntegerFormatStyle<Int64>.Currency(code: "KWD", locale: locale)
                .presentation(.standard)
                .scale(1.0 / 1000.0)
        )

        #expect(ours == reference, "Locale \(locale.identifier): got \(ours.debugDescription), want \(reference.debugDescription)")
    }

    // MARK: - Structural invariant: isoCode presentation

    @Test(
        "presentation(.isoCode) always contains the ISO currency code",
        arguments: localizationTestLocales
    )
    func isoCodeContainsCurrencyCode(locale: Locale) {
        let style = Money<GBP>.FormatStyle(locale: locale).presentation(.isoCode)
        let result = style.format(Money<GBP>(minorUnits: 12_345))
        #expect(result.contains("GBP"), "Locale \(locale.identifier): \(result.debugDescription) should contain \"GBP\"")
    }

    // MARK: - Structural invariant: grouping(.never)

    @Test(
        "grouping(.never) output is no longer than grouping(.automatic)",
        arguments: localizationTestLocales
    )
    func groupingNeverNoLongerThanAutomatic(locale: Locale) {
        // 12,345,678 major units — large enough to trigger thousands grouping in any locale.
        // Note: sign is left as .automatic (default) to avoid the ICU sign-auto+group-off bug.
        let amount = Money<GBP>(minorUnits: 1_234_567_800)
        let withGrouping    = Money<GBP>.FormatStyle(locale: locale).grouping(.automatic).format(amount)
        let withoutGrouping = Money<GBP>.FormatStyle(locale: locale).grouping(.never).format(amount)
        #expect(
            withoutGrouping.count <= withGrouping.count,
            "Locale \(locale.identifier): grouping(.never) (\(withoutGrouping.count) chars) should be ≤ grouping(.automatic) (\(withGrouping.count) chars)"
        )
    }
}
