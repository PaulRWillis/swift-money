import SwiftMoney
import Testing

#warning("Lots of tests will fail when the test device locale is changed. This needs addressing through proper test infrastructure. Direct comparison with Int FormatStyle?")
struct Money_CustomStringConvertibleTests {
    @Test
    func whenPrintDescription_shouldUseFormattedStringValue() {
        let money = Money<GBP>(minorUnits: 199)

        #expect(money.description == "£1.99")
    }
}
