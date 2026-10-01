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
            (code: "SAFEMOON", fields: "SM"),  // eight characters, the most Core accepts
            (code: "G-P", fields: "?"),        // not a code
            (code: "GB", fields: "?"),         // too short to be a code
            (code: "USD", fields: "$"),
        ])

        #expect(entries.unusableCodes == [
            .longerThanTheTablesHold("USDT"),
            .longerThanTheTablesHold("SAFEMOON"),
            .notACurrencyCode("G-P"),
            .notACurrencyCode("GB"),
        ])
        #expect(entries.held.map(\.code) == [gbp, usd])
        #expect(entries.held.map(\.fields) == ["£", "$"])
    }

    @Test("Text that isn't a currency code is listed as given, and a long code as Core reads it")
    func listsEachUnusableCodeByItsKind() {
        let entries = LocaleCurrencyEntries(parsing: [
            (code: "g-p", fields: "?"),
            (code: "usdt", fields: "₮"),
        ])

        #expect(entries.unusableCodes == [
            .notACurrencyCode("g-p"),
            .longerThanTheTablesHold("USDT"),
        ])
        #expect(entries.held.isEmpty)
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

        #expect(entries.unusableCodes == [.longerThanTheTablesHold(usdt)])
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

        #expect(mapped.unusableCodes == [.longerThanTheTablesHold("USDT")])
        #expect(mapped.held.map(\.code) == entries.held.map(\.code))
        #expect(mapped.held.map(\.fields) == [10, 30])
    }

    @Test("A map whose transform throws on one entry throws that entry's error")
    func mapThrowsTheTransformsError() {
        let entries = LocaleCurrencyEntries(parsing: [
            (code: "GBP", fields: "£"),
            (code: "USD", fields: "$"),
            (code: "EUR", fields: "€"),
        ])

        #expect(throws: LocaleSkip.unrepresentableGap("\t", symbol: "$")) {
            try entries.map { (symbol: String) throws(LocaleSkip) -> String in
                guard symbol != "$" else {
                    throw .unrepresentableGap("\t", symbol: symbol)
                }

                return symbol
            }
        }
    }
}
