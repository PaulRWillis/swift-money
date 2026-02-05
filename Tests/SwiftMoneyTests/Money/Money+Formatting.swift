import SwiftMoney
import Testing

struct Money_FormatStyleTests {

    @Test
    func shouldFormatAsTypedCurrency() {
        let pounds = Money<GBP>.FormatStyle()
        let formattedPounds = pounds.format(Money<GBP>(minorUnits: 100))
        print(">>> Formatted: \(formattedPounds)")
        #expect(formattedPounds == "£1.00")
    }
}
