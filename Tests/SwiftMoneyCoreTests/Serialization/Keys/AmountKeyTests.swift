import SwiftMoneyCore
import Testing

@Suite("AmountKey Tests")
struct AmountKeyTests {

    @Test("A string literal creates a key")
    func literalCreatesAKey() {
        let key: AmountKey = "value"

        #expect(String(key) == "value")
    }

    @Test("A key built from a string round trips through the String bridge")
    func roundTripsThroughTheStringBridge() {
        let key = AmountKey("value")

        #expect(String(key) == "value")
    }

    @Test("The default key is \"amount\"")
    func defaultIsAmount() {
        #expect(String(AmountKey.default) == "amount")
    }

    @Test("Keys built the same way are equal")
    func equalKeysAreEqual() {
        #expect(AmountKey("value") == AmountKey("value"))
        #expect(AmountKey("value") != AmountKey("ccy"))
    }
}
