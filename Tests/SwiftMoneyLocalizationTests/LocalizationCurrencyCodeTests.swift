import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

@Suite("Localization Currency Code Tests")
struct LocalizationCurrencyCodeTests {

    @Test(
        "A three-character code is keyed by its characters, first highest",
        arguments: [
            ("GBP", 0b000111_000010_010000),
            ("EUR", 0b000101_010101_010010),
            ("JPY", 0b001010_010000_011001),
            ("999", 0b100100_100100_100100),
        ] as [(CurrencyCode, UInt64)]
    )
    func keysAThreeCharacterCode(_ code: CurrencyCode, _ value: UInt64) {
        #expect(Localization.CurrencyCode(code)?.value == value)
    }

    @Test(
        "A code longer than three characters has no key",
        arguments: ["USDT", "1INCH", "SAFEMOON"] as [CurrencyCode]
    )
    func refusesALongerCode(_ code: CurrencyCode) {
        #expect(Localization.CurrencyCode(code) == nil)
    }

    @Test("Keys sort in the order of their codes")
    func sortsByCode() throws {
        let eur = try tableCode("EUR")
        let gbp = try tableCode("GBP")
        let usd = try tableCode("USD")

        #expect([usd, eur, gbp].sorted() == [eur, gbp, usd])
    }

    @Test("Keys sort as their codes' packed words do")
    func sortsAsThePackedWords() throws {
        let codes = Currency.allISO4217.map(\.code).sorted { $0.compactValue < $1.compactValue }
        let keys = try codes.map { try #require(Localization.CurrencyCode($0)) }

        #expect(keys == keys.sorted())
    }

    @Test("Every ISO 4217 currency the library ships has a key")
    func everyShippedCurrencyHasAKey() {
        for currency in Currency.allISO4217 {
            #expect(Localization.CurrencyCode(currency.code) != nil, "\(currency.code)")
        }
    }

    @Test("The widest key fits its digits")
    func widestKeyFitsItsDigits() throws {
        let widest = try tableCode("999")  // 9 packs highest

        #expect(widest.value >> (Localization.CurrencyCode.fieldWidth * BlobDigits.bits) == 0)
    }
}
