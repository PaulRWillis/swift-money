import SwiftMoneyCore
import Testing

@Suite("CurrencyKey Tests")
struct CurrencyKeyTests {

    @Test("A string literal creates a key")
    func literalCreatesAKey() {
        let key: CurrencyKey = "ccy"

        #expect(String(key) == "ccy")
    }

    @Test("A key built from a string round trips through the String bridge")
    func roundTripsThroughTheStringBridge() {
        let key = CurrencyKey("ccy")

        #expect(String(key) == "ccy")
    }

    @Test("The default key is \"currency\"")
    func defaultIsCurrency() {
        #expect(String(CurrencyKey.default) == "currency")
    }

    @Test("Keys built the same way are equal")
    func equalKeysAreEqual() {
        #expect(CurrencyKey("ccy") == CurrencyKey("ccy"))
        #expect(CurrencyKey("ccy") != CurrencyKey("value"))
    }
}
