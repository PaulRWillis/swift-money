import SwiftMoney
import Testing

struct Money_FormatStyleTests {

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
}
