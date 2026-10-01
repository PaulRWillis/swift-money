import CLDRLocaleSkips
import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

@Suite("Locale Currency Entries Tests")
struct LocaleCurrencyEntriesTests {

    @Test("A code the tables can't hold is listed as unusable, and its fields are left out")
    func listsAnUnusableCode() throws {
        let gbp = try tableCode("GBP")
        let usd = try tableCode("USD")

        let entries = LocaleCurrencyEntries(parsing: [
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

        let entries = LocaleCurrencyEntries(parsing: [(code: "gbp", fields: "£")])

        #expect(entries.held.map(\.code) == [gbp])
        #expect(entries.unusableCodes.isEmpty)
    }

    @Test("Held entries keep the order they were given in")
    func keepsTheGivenOrder() {
        let entries = LocaleCurrencyEntries(parsing: [
            (code: "USD", fields: 1),
            (code: "EUR", fields: 2),
        ])

        #expect(entries.held.map(\.fields) == [1, 2])
        #expect(entries.unusableCodes.isEmpty)
    }

    @Test("A Core code the tables can't hold is listed, and the rest are held in order")
    func splitsCoreCodes() throws {
        let gbp: CurrencyCode = "GBP"
        let usdt: CurrencyCode = "USDT"
        let usd: CurrencyCode = "USD"

        let entries = LocaleCurrencyEntries([
            (code: gbp, fields: "£"),
            (code: usdt, fields: "₮"),
            (code: usd, fields: "$"),
        ])

        #expect(entries.unusableCodes == ["USDT"])
        #expect(entries.held.map(\.code) == [try tableCode("GBP"), try tableCode("USD")])
        #expect(entries.held.map(\.fields) == ["£", "$"])
    }

    @Test("A mapped split keeps its unusable codes and its held codes")
    func mapKeepsTheSplit() throws {
        let entries = LocaleCurrencyEntries(parsing: [
            (code: "GBP", fields: 1),
            (code: "USDT", fields: 2),
            (code: "USD", fields: 3),
        ])

        let mapped = entries.map { $0 * 10 }

        #expect(mapped.unusableCodes == ["USDT"])
        #expect(mapped.held.map(\.code) == entries.held.map(\.code))
        #expect(mapped.held.map(\.fields) == [10, 30])
    }
}
