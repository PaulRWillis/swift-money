import SwiftMoneyLocalization
import Testing

// The separators an imposing numbering system carries.
@Suite("Numbering System Symbols Tests")
struct NumberingSystemSymbolsTests {

    @Test("Holds the decimal, grouping and minus a system imposes")
    func holdsSymbols() {
        let symbols = NumberingSystemSymbols(decimalSeparator: "٫", groupingSeparator: "٬", minusSign: "\u{061C}-")
        #expect(symbols.decimalSeparator == "٫")
        #expect(symbols.groupingSeparator == "٬")
        #expect(symbols.minusSign == "\u{061C}-")
    }
}
