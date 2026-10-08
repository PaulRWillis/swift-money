import SwiftMoneyLocalization
import Testing

@Suite("Generated Locale Keys Tests")
struct GeneratedLocaleKeysTests {

    // A repeated or out-of-order key would make the binary search return the wrong locale's row.
    @Test("The covered identifiers are strictly increasing in UTF-8 byte order")
    func identifiersAreStrictlyIncreasing() {
        let identifiers = MoneyLocalization.coveredLocaleIdentifiers

        for (earlier, later) in zip(identifiers, identifiers.dropFirst()) {
            #expect(earlier.utf8.lexicographicallyPrecedes(later.utf8), "\(earlier) is not before \(later)")
        }
    }
}
