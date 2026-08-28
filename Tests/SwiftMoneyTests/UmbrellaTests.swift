import Foundation
import SwiftMoney
import Testing

// The umbrella's whole purpose is that one `import SwiftMoney` brings in both the core types and the
// Foundation-backed surface. This exercises a symbol from each — `GBP` from SwiftMoneyCore, `FormatStyle`
// from SwiftMoneyFoundation — under that single import. If either `@_exported import` is dropped, this
// stops compiling. (`Foundation` is imported only for `Locale`, which is Foundation's, not ours.)
@Suite("SwiftMoney umbrella")
struct UmbrellaTests {

    @Test("One import reaches both the core and the Foundation surface")
    func oneImportReachesBoth() {
        let amount = GBP(minorUnits: 4_99)   // SwiftMoneyCore
        let formatted = GBP.FormatStyle()    // SwiftMoneyFoundation
            .locale(Locale(identifier: "en_GB"))
            .format(amount)

        #expect(formatted.contains("4.99"))
    }
}
