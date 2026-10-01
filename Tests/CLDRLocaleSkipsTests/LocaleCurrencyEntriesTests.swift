import CLDRLocaleSkips
import SwiftMoneyLocalization
import Testing

@Suite("Locale Currency Entries Tests")
struct LocaleCurrencyEntriesTests {

    @Test("A code the tables can't hold is listed as unusable, and its fields are left out")
    func listsAnUnusableCode() throws {
        let gbp = try tableCode("GBP")
        let usd = try tableCode("USD")

        let entries = LocaleCurrencyEntries([
            (code: "GBP", fields: "£"),
            (code: "USDT", fields: "₮"),       // a code, too long for the tables
            (code: "SAFEMOON", fields: "SM"),  // the longest code
            (code: "G-P", fields: "?"),        // not a code
            (code: "GB", fields: "?"),         // too short to be a code
            (code: "USD", fields: "$"),
        ])

        #expect(entries.unusableCodes == ["USDT", "SAFEMOON", "G-P", "GB"])
        #expect(entries.held.map(\.code) == [gbp, usd])
        #expect(entries.held.map(\.fields) == ["£", "$"])
    }

    @Test("A code is held under the currency it spells, in any case")
    func readsACodeInAnyCase() throws {
        let gbp = try tableCode("GBP")

        let entries = LocaleCurrencyEntries([(code: "gbp", fields: "£")])

        #expect(entries.held.map(\.code) == [gbp])
        #expect(entries.unusableCodes.isEmpty)
    }

    @Test("Held entries keep the order they were given in")
    func keepsTheGivenOrder() {
        let entries = LocaleCurrencyEntries([(code: "USD", fields: 1), (code: "EUR", fields: 2)])

        #expect(entries.held.map(\.fields) == [1, 2])
        #expect(entries.unusableCodes.isEmpty)
    }
}
