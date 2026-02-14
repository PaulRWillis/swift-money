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
        #expect(dollars == "$1.00")
    }

    @Test
    func whenFormatAsCurrency_shouldRespectMinimalQuantisation() {
        // Japanese Yen (JPY) has no minor units, unlike e.g. US Dollars (USD) with 100 cents to the dollar
        let yenFormatStyle = Money<JPY>.FormatStyle()
        let yen = yenFormatStyle.format(Money<JPY>(minorUnits: 100))
        #expect(yen == "¥100")
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

        let positiveMoney = Money<GBP>(minorUnits: 100)
        let positiveFormatted = formatStyle.format(positiveMoney)
        #expect(positiveFormatted == "£1.00")

        let negativeMoney = Money<GBP>(minorUnits: -100)
        let negativeFormatted = formatStyle.format(negativeMoney)
        #expect(negativeFormatted == "-£1.00")

        let zeroMoney = Money<GBP>(minorUnits: 0)
        let zeroFormatted = formatStyle.format(zeroMoney)
        #expect(zeroFormatted == "£0.00")
    }

    @Test
    func sign_shouldSupportAlwaysShowingSign() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .always())

        let positiveMoney = Money<GBP>(minorUnits: 100)
        let positiveFormatted = formatStyle.format(positiveMoney)
        #expect(positiveFormatted == "+£1.00")

        let negativeMoney = Money<GBP>(minorUnits: -100)
        let negativeFormatted = formatStyle.format(negativeMoney)
        #expect(negativeFormatted == "-£1.00")

        let zeroMoney = Money<GBP>(minorUnits: 0)
        let zeroFormatted = formatStyle.format(zeroMoney)
        #expect(zeroFormatted == "+£0.00") // including zero
    }

    @Test
    func sign_shouldSupportAlwaysShowingSignExceptZero() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .always(showZero: false))

        let positiveMoney = Money<GBP>(minorUnits: 100)
        let positiveFormatted = formatStyle.format(positiveMoney)
        #expect(positiveFormatted == "+£1.00")

        let negativeMoney = Money<GBP>(minorUnits: -100)
        let negativeFormatted = formatStyle.format(negativeMoney)
        #expect(negativeFormatted == "-£1.00")

        let zeroMoney = Money<GBP>(minorUnits: 0)
        let zeroFormatted = formatStyle.format(zeroMoney)
        #expect(zeroFormatted == "£0.00") // except zero
    }

    @Test
    func sign_shouldSupportAccountingFormat() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .accounting)

        let positiveMoney = Money<GBP>(minorUnits: 100)
        let positiveFormatted = formatStyle.format(positiveMoney)
        #expect(positiveFormatted == "£1.00")

        let negativeMoney = Money<GBP>(minorUnits: -100)
        let negativeFormatted = formatStyle.format(negativeMoney)
        #expect(negativeFormatted == "(£1.00)")

        let zeroMoney = Money<GBP>(minorUnits: 0)
        let zeroFormatted = formatStyle.format(zeroMoney)
        #expect(zeroFormatted == "£0.00")
    }

    @Test
    func sign_shouldSupportAccountingAlways() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .accountingAlways(showZero: true))

        let positiveMoney = Money<GBP>(minorUnits: 100)
        let positiveFormatted = formatStyle.format(positiveMoney)
        #expect(positiveFormatted == "+£1.00")

        let negativeMoney = Money<GBP>(minorUnits: -100)
        let negativeFormatted = formatStyle.format(negativeMoney)
        #expect(negativeFormatted == "(£1.00)")

        let zeroMoney = Money<GBP>(minorUnits: 0)
        let zeroFormatted = formatStyle.format(zeroMoney)
        #expect(zeroFormatted == "+£0.00")
    }

    @Test
    func sign_shouldSupportAccountingAlwaysExceptZero() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .accountingAlways(showZero: false))

        let positiveMoney = Money<GBP>(minorUnits: 100)
        let positiveFormatted = formatStyle.format(positiveMoney)
        #expect(positiveFormatted == "+£1.00")

        let negativeMoney = Money<GBP>(minorUnits: -100)
        let negativeFormatted = formatStyle.format(negativeMoney)
        #expect(negativeFormatted == "(£1.00)")

        let zeroMoney = Money<GBP>(minorUnits: 0)
        let zeroFormatted = formatStyle.format(zeroMoney)
        #expect(zeroFormatted == "£0.00")
    }

    @Test
    func sign_shouldSupportNeverShowingSign() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .never)

        let positiveMoney = Money<GBP>(minorUnits: 100)
        let positiveFormatted = formatStyle.format(positiveMoney)
        #expect(positiveFormatted == "£1.00")

        let negativeMoney = Money<GBP>(minorUnits: -100)
        let negativeFormatted = formatStyle.format(negativeMoney)
        #expect(negativeFormatted == "£1.00")

        let zeroMoney = Money<GBP>(minorUnits: 0)
        let zeroFormatted = formatStyle.format(zeroMoney)
        #expect(zeroFormatted == "£0.00")
    }

    @Test
    func sign_shouldSupportAutomaticConfiguration() {
        let formatStyle = Money<GBP>.FormatStyle()
            .sign(strategy: .automatic)

        let positiveMoney = Money<GBP>(minorUnits: 100)
        let positiveFormatted = formatStyle.format(positiveMoney)
        #expect(positiveFormatted == "£1.00")

        let negativeMoney = Money<GBP>(minorUnits: -100)
        let negativeFormatted = formatStyle.format(negativeMoney)
        #expect(negativeFormatted == "-£1.00")

        let zeroMoney = Money<GBP>(minorUnits: 0)
        let zeroFormatted = formatStyle.format(zeroMoney)
        #expect(zeroFormatted == "£0.00")
    }
}
