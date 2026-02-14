import Foundation
import SwiftMoney
import Testing

struct Money_FormatStyleTests {
    private var localesAndMoneys: [(locale: Locale, stringValue: String)] = [
        (Locale(identifier: "en_GB"), "€1.05"),
        (Locale(identifier: "en_US"), "€1.05"),
        (Locale(identifier: "fr"), "1,05 €"),
    ]

    @Test
    func whenFormatAsCurrency_shouldRepresentAsTypedCurrency() {
        let poundFormatStyle = Money<GBP>.FormatStyle()
        let pounds = poundFormatStyle.format(Money<GBP>(minorUnits: 100))
        #expect(pounds == "£1.00")

        let euroFormatStyle = Money<EUR>.FormatStyle()
        let euros = euroFormatStyle.format(Money<EUR>(minorUnits: 100))
        #expect(euros == "€1.00")

        let dollarFormatStyle = Money<USD>.FormatStyle()
        let dollars = dollarFormatStyle.format(Money<USD>(minorUnits: 100))
        #expect(dollars == "US$1.00")
    }

    @Test
    func whenFormatAsCurrency_shouldRespectMinimalQuantisation() {
        // Japanese Yen (JPY) has no minor units, unlike e.g. US Dollars (USD) with 100 cents to the dollar
        let yenFormatStyle = Money<JPY>.FormatStyle()
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
        let formatStyle = Money<GBP>.FormatStyle()

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "-£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportAlwaysShowingSign() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .always())

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "+£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "-£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "+£0.00")
    }

    @Test
    func sign_shouldSupportAlwaysShowingSignExceptZero() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .always(showZero: false))

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "+£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "-£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportAccountingFormat() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .accounting)

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "(£1.00)")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportAccountingAlways() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .accountingAlways(showZero: true))

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "+£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "(£1.00)")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "+£0.00")
    }

    @Test
    func sign_shouldSupportAccountingAlwaysExceptZero() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .accountingAlways(showZero: false))

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "+£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "(£1.00)")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportNeverShowingSign() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .never)

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -200)) == "£2.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    @Test
    func sign_shouldSupportAutomaticConfiguration() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .automatic)

        #expect(formatStyle.format(Money<GBP>(minorUnits: 100)) == "£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: -100)) == "-£1.00")
        #expect(formatStyle.format(Money<GBP>(minorUnits: 0)) == "£0.00")
    }

    // MARK: - Presentation formatting

    @Test
    func presentation_shouldDefaultToAutomatic() {
        // Can we do this for multiple currencies? Iterate over array?
        #expect(Money<USD>.FormatStyle().format(Money<USD>(minorUnits: 201)) == "US$2.01")
        #expect(Money<USD>.FormatStyle().format(Money<USD>(minorUnits: -201)) == "-US$2.01")
        #expect(Money<USD>.FormatStyle().format(Money<USD>(minorUnits: 0)) == "US$0.00")
    }

    @Test
    func presentation_shouldSupportFullCurrencyName() {
        let formatStyle = Money<USD>.FormatStyle()
            .presentation(.fullName)

        #expect(formatStyle.format(Money<USD>(minorUnits: 307)) == "3.07 US dollars")
        #expect(formatStyle.format(Money<USD>(minorUnits: -455)) == "-4.55 US dollars")
        #expect(formatStyle.format(Money<USD>(minorUnits: 0)) == "0.00 US dollars")
    }

    @Test
    func presentation_shouldSupportISOCode() {
        let formatStyle = Money<USD>.FormatStyle()
            .presentation(.isoCode)

        #expect(formatStyle.format(Money<USD>(minorUnits: 307)) == "USD 3.07")
        #expect(formatStyle.format(Money<USD>(minorUnits: -455)) == "-USD 4.55")
        #expect(formatStyle.format(Money<USD>(minorUnits: 0)) == "USD 0.00")
    }

    @Test
    func presentation_shouldSupportNarrowCurrencyName() {
        let formatStyle = Money<USD>.FormatStyle()
            .presentation(.narrow)

        #expect(formatStyle.format(Money<USD>(minorUnits: 307)) == "$3.07")
        #expect(formatStyle.format(Money<USD>(minorUnits: -455)) == "-$4.55")
        #expect(formatStyle.format(Money<USD>(minorUnits: 0)) == "$0.00")
    }

    @Test
    func presentation_shouldSupportStandardCurrencyName() {
        let formatStyle = Money<USD>.FormatStyle()
            .presentation(.standard)

        #expect(formatStyle.format(Money<USD>(minorUnits: 307)) == "US$3.07")
        #expect(formatStyle.format(Money<USD>(minorUnits: -455)) == "-US$4.55")
        #expect(formatStyle.format(Money<USD>(minorUnits: 0)) == "US$0.00")
    }
}
