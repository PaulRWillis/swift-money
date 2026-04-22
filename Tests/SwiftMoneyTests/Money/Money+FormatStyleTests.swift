import Foundation
import SwiftMoney
import Testing

@Suite("Money - FormatStyle")
struct Money_FormatStyleTests {
    private var localesAndMoneys: [(locale: Locale, stringValue: String)] = [
        (Locale(identifier: "en_GB"), "€1.05"),
        (Locale(identifier: "en_US"), "€1.05"),
        (Locale(identifier: "fr"), "1,05\u{00A0}€"),
    ]

    private let enUS = Locale(identifier: "en_US")
    private let enGB = Locale(identifier: "en_GB")

    @Test
    func whenFormatAsCurrency_shouldRepresentAsTypedCurrency() {
        let poundFormatStyle = Money<GBP>.FormatStyle(locale: enGB)
        let pounds = poundFormatStyle.format(Money<GBP>(minorUnits: 100))
        #expect(pounds == "£1.00")

        let euroFormatStyle = Money<EUR>.FormatStyle(locale: enGB)
        let euros = euroFormatStyle.format(Money<EUR>(minorUnits: 100))
        #expect(euros == "€1.00")

        let dollarFormatStyle = Money<USD>.FormatStyle(locale: enGB)
        let dollars = dollarFormatStyle.format(Money<USD>(minorUnits: 100))
        #expect(dollars == "US$1.00")
    }

    @Test
    func whenFormatAsCurrency_shouldRespectMinimalQuantisation() {
        // Japanese Yen (JPY) has no minor units, unlike e.g. US Dollars (USD) with 100 cents to the dollar
        let yenFormatStyle = Money<JPY>.FormatStyle(locale: enGB)
        let yen = yenFormatStyle.format(Money<JPY>(minorUnits: 100))
        #expect(yen == "JP¥100")
    }

    @Test
    func whenFormatAsCurrencyWithLocale_shouldRespectLocaleCurrencyRepresentation() {
        localesAndMoneys.forEach { (locale, expectedValue) in
            let formatStyle = Money<EUR>.FormatStyle(locale: locale)
            let formattedValue = formatStyle.format(Money<EUR>(minorUnits: 105))

            #expect(formattedValue == expectedValue, "String representations should be equal for locale: \(locale.identifier)")
        }
    }

    // MARK: - Sign formatting

    @Test
    func sign_shouldDefaultToAutomatic() {
        let formatStyle = Money<GBP>.FormatStyle(locale: enGB)

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "-£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportAlwaysShowingSign() {
        let formatStyle = Money<GBP>.FormatStyle(locale: enGB)
            .sign(strategy: .always())

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "+£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "-£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "+£0.00")
    }

    @Test
    func sign_shouldSupportAlwaysShowingSignExceptZero() {
        let formatStyle = Money<GBP>.FormatStyle(locale: enGB)
            .sign(strategy: .always(showZero: false))

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "+£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "-£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportAccountingFormat() {
        let formatStyle = Money<GBP>.FormatStyle(locale: enGB)
            .sign(strategy: .accounting)

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "(£1.00)")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportAccountingAlways() {
        let formatStyle = Money<GBP>.FormatStyle(locale: enGB)
            .sign(strategy: .accountingAlways(showZero: true))

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "+£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "(£1.00)")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "+£0.00")
    }

    @Test
    func sign_shouldSupportAccountingAlwaysExceptZero() {
        let formatStyle = Money<GBP>.FormatStyle(locale: enGB)
            .sign(strategy: .accountingAlways(showZero: false))

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "+£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "(£1.00)")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportNeverShowingSign() {
        let formatStyle = Money<GBP>.FormatStyle(locale: enGB)
            .sign(strategy: .never)

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -200)) == "£2.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportAutomaticConfiguration() {
        let formatStyle = Money<GBP>.FormatStyle(locale: enGB)
            .sign(strategy: .automatic)

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "-£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    // MARK: - Presentation formatting

    @Test
    func presentation_shouldDefaultToAutomatic() {
        // .standard (default) is locale-aware: en_GB shows USD as "US$" (foreign currency)
        let style = Money<USD>.FormatStyle(locale: enGB)
        #expect(style.format(Money<USD>(minorUnits: 201)) == "US$2.01")
        #expect(style.format(Money<USD>(minorUnits: -201)) == "-US$2.01")
        #expect(style.format(Money<USD>(minorUnits: 0)) == "US$0.00")
    }

    @Test
    func presentation_shouldSupportFullCurrencyName() {
        let formatStyle = Money<USD>.FormatStyle(locale: enUS)
            .presentation(.fullName)

        #expect(formatStyle.format(Money<USD>(minorUnits: 307)) == "3.07 US dollars")
        #expect(formatStyle.format(Money<USD>(minorUnits: -455)) == "-4.55 US dollars")
        #expect(formatStyle.format(Money<USD>(minorUnits: 0)) == "0.00 US dollars")
    }

    @Test
    func presentation_shouldSupportISOCode() {
        let formatStyle = Money<USD>.FormatStyle(locale: enUS)
            .presentation(.isoCode)

        #expect(formatStyle.format(Money<USD>(minorUnits: 307)) == "USD 3.07")
        #expect(formatStyle.format(Money<USD>(minorUnits: -455)) == "-USD 4.55")
        #expect(formatStyle.format(Money<USD>(minorUnits: 0)) == "USD 0.00")
    }

    @Test
    func presentation_shouldSupportNarrowCurrencyName() {
        let formatStyle = Money<USD>.FormatStyle(locale: enUS)
            .presentation(.narrow)

        #expect(formatStyle.format(Money<USD>(minorUnits: 307)) == "$3.07")
        #expect(formatStyle.format(Money<USD>(minorUnits: -455)) == "-$4.55")
        #expect(formatStyle.format(Money<USD>(minorUnits: 0)) == "$0.00")
    }

    @Test
    func presentation_shouldSupportStandardCurrencyName() {
        // en_GB shows USD as "US$" via unit-width-short (foreign currency needs disambiguation)
        let formatStyle = Money<USD>.FormatStyle(locale: enGB)
            .presentation(.standard)

        #expect(formatStyle.format(Money<USD>(minorUnits: 307)) == "US$3.07")
        #expect(formatStyle.format(Money<USD>(minorUnits: -455)) == "-US$4.55")
        #expect(formatStyle.format(Money<USD>(minorUnits: 0)) == "US$0.00")
    }
    // MARK: - New modifiers

    @Test("grouping(.automatic) applies locale-appropriate thousands separator")
    func groupingAutomatic() {
        let style = Money<USD>.FormatStyle(locale: enGB).grouping(.automatic)
        #expect(style.format(Money<USD>(minorUnits: 1_000_000)).contains(","))
    }

    @Test("grouping(.never) disables thousands separator (JPY — minQ=1, exact scale)")
    func groupingNeverJPY() {
        // grouping(.never) on currencies with minQ>1 (e.g. GBP/USD) triggers a Foundation
        // ICU skeleton issue when scale/0.01 is combined with group-off — use JPY (minQ=1,
        // scale=1.0 exactly) to verify behaviour without hitting that limitation.
        let style = Money<JPY>.FormatStyle(locale: enGB).grouping(.never)
        #expect(style.format(Money<JPY>(minorUnits: 10_000)) == "JP¥10000")
    }

    @Test("scale(2.0) doubles the displayed major-unit value")
    func scaleDoubles() {
        // £1.50 × 2 = £3.00
        let style = Money<GBP>.FormatStyle(locale: enGB).scale(2.0)
        #expect(style.format(Money<GBP>(minorUnits: 150)) == "£3.00")
    }

    @Test("scale(0.5) halves the displayed major-unit value")
    func scaleHalves() {
        // £2.00 × 0.5 = £1.00
        let style = Money<GBP>.FormatStyle(locale: enGB).scale(0.5)
        #expect(style.format(Money<GBP>(minorUnits: 200)) == "£1.00")
    }

    @Test("notation(.compactName) abbreviates large amounts")
    func notationCompactName() {
        // en_GB compact-short uses lowercase k (ICU CLDR convention)
        let style = Money<GBP>.FormatStyle(locale: enGB).notation(.compactName)
        #expect(style.format(Money<GBP>(minorUnits: 1_500_000)) == "£15k")
    }

    @Test("formatted(_:) convenience applies the given style")
    func formattedConvenience() {
        let style = Money<GBP>.FormatStyle(locale: enGB).sign(strategy: .always())
        let money = Money<GBP>(minorUnits: 150)
        #expect(money.formatted(style) == "+£1.50")
    }

    @Test("locale(_:) modifier changes locale")
    func localeModifier() {
        let fr = Locale(identifier: "fr")
        let style = Money<EUR>.FormatStyle().locale(fr)
        // French locale uses non-breaking space (U+00A0) before the € symbol
        #expect(style.format(Money<EUR>(minorUnits: 105)) == "1,05\u{00A0}€")
    }
}
