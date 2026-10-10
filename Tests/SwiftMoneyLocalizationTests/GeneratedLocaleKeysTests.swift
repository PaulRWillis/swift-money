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

    // The lookup tries nothing after the identifier itself once its language passes 8 bytes, which
    // finds every stored key only while no stored language is longer.
    @Test("No covered identifier's language is longer than 8 bytes")
    func languagesFitBCP47() {
        let tooLong = MoneyLocalization.coveredLocaleIdentifiers.filter { identifier in
            identifier.utf8.prefix { $0 != UInt8(ascii: "-") }.count > 8
        }

        #expect(tooLong.isEmpty)
    }
}
