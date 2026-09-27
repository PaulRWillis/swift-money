import SwiftMoneyLocalization
import Testing

// The provenance sum type: two distinct shapes, one carrying separators and one carrying none.
@Suite("Separator Provenance Tests")
struct SeparatorProvenanceTests {

    @Test("Reuse never carries separators; imposing carries its own")
    func casesDiffer() {
        let symbols = NumberingSystemSymbols(decimalSeparator: "٫", groupingSeparator: "٬", minusSign: "-")
        #expect(SeparatorProvenance.imposesOwn(symbols) != .reusesLocale)
        #expect(SeparatorProvenance.imposesOwn(symbols) == .imposesOwn(symbols))
    }
}
