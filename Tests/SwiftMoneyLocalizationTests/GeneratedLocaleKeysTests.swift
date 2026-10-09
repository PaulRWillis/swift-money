import SwiftMoneyLocalization
import Testing

@Suite("Generated Locale Keys Tests")
struct GeneratedLocaleKeysTests {

    // A repeated or out-of-order key would make the binary search return the wrong locale's row.
    @Test("The covered identifiers are strictly increasing in folded byte order")
    func identifiersAreStrictlyIncreasing() {
        let identifiers = MoneyLocalization.coveredLocaleIdentifiers

        for (earlier, later) in zip(identifiers, identifiers.dropFirst()) {
            let earlierBytes = IteratorSequence(LocaleKey(LocaleIdentifier(earlier)).bytes.makeIterator())
            let laterBytes = IteratorSequence(LocaleKey(LocaleIdentifier(later)).bytes.makeIterator())

            #expect(earlierBytes.lexicographicallyPrecedes(laterBytes), "\(earlier) is not before \(later)")
        }
    }
}
