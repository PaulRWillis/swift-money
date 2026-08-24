import Foundation
import SwiftMoney
import Testing

@Suite("CurrencyCode Tests")
struct CurrencyCodeTests {

    @Test(
        "Codes of three to eight uppercase alphanumerics are accepted",
        arguments: [
            "GBP",       // ISO 4217
            "EUR",
            "XAU",       // ISO precious metal
            "BTC",       // crypto, 3
            "USDT",      // crypto, 4
            "MATIC",     // crypto, 5
            "SAFEMOON",  // crypto, 8: the longest accepted
            "1INCH",     // leading digit
            "401K",      // digits throughout
            "LTY",       // in-app currency
            "GEMS",
        ]
    )
    func acceptsValidCodes(_ raw: String) throws {
        let code = try #require(CurrencyCode(string: raw))

        #expect(String(code) == raw)
    }

    @Test("Lowercase input is normalized to uppercase")
    func lowercaseIsNormalized() {
        #expect(CurrencyCode(string: "gbp").map(String.init) == "GBP")
        #expect(CurrencyCode(string: "uSdT").map(String.init) == "USDT")
    }

    @Test("A code of the longest accepted length is normalized and round-trips")
    func longestCodeIsNormalized() {
        #expect(CurrencyCode(string: "safemoon").map(String.init) == "SAFEMOON")
    }

    @Test("Codes differing only by case are the same currency")
    func caseInsensitiveEquality() {
        #expect(CurrencyCode(string: "gbp") == CurrencyCode(string: "GBP"))
        #expect(CurrencyCode(string: "gBp") == CurrencyCode(string: "GBP"))
    }

    @Test("Codes differing only by case hash the same")
    func caseInsensitiveHashing() throws {
        let lower = try #require(CurrencyCode(string: "gbp"))
        let upper = try #require(CurrencyCode(string: "GBP"))

        #expect(Set([lower, upper]).count == 1)
    }

    @Test(
        "Codes outside three to eight characters are rejected",
        arguments: ["", "G", "AB", "TOOLONGCODE", "ABCDEFGHI"]
    )
    func rejectsWrongLength(_ raw: String) {
        #expect(CurrencyCode(string: raw) == nil)
    }

    @Test(
        "Codes containing anything but ASCII letters and digits are rejected",
        arguments: [
            "G-P",          // hyphen
            "G P",          // space
            "LTY_PTS",      // underscore
            "$5S",          // punctuation
            "1%X",
            "💷💷💷",          // emoji
            "空气币",          // CJK
            "ÉUR",          // accented Latin
            "GB\u{200B}P",  // zero-width space
        ]
    )
    func rejectsNonAlphanumeric(_ raw: String) {
        #expect(CurrencyCode(string: raw) == nil)
    }

    // These are the cases `Character.isNumber` would wrongly admit: it is true for every one of
    // them. Only a byte-level ASCII check rejects them, so these tests pin that choice.
    @Test(
        "Digits outside ASCII are rejected",
        arguments: [
            "٣٣٣",  // Arabic-Indic
            "३३३",  // Devanagari
            "３３３",  // fullwidth
            "³³³",  // superscript
            "ⅢⅢⅢ",  // Roman numeral
            "½½½",  // vulgar fraction
        ]
    )
    func rejectsNonASCIIDigits(_ raw: String) {
        #expect(CurrencyCode(string: raw) == nil)
    }

    // Regression: uppercasing before validating would turn "ß" into "SS", so a two-character
    // non-ASCII input would pass both the character and the length check.
    @Test("Characters that grow when uppercased are still rejected")
    func rejectsCharactersThatGrowWhenUppercased() {
        #expect(CurrencyCode(string: "ßß") == nil)
        #expect(CurrencyCode(string: "ßßß") == nil)
    }

    @Test("A valid string literal creates a code")
    func validLiteral() {
        let code: CurrencyCode = "GBP"

        #expect(code == CurrencyCode(string: "GBP"))
    }

    @Test("A lowercase string literal is normalized")
    func lowercaseLiteralIsNormalized() {
        let code: CurrencyCode = "gbp"

        #expect(String(code) == "GBP")
    }

    @Test("An invalid string literal traps")
    func invalidLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let code: CurrencyCode = "not a currency"
            blackHole(code)
        }
    }

    // The failable initializer is labeled because an unlabeled one would be unreachable: with
    // ExpressibleByStringLiteral present, `CurrencyCode("...")` always resolves to the literal
    // initializer, which traps rather than returning nil. Same trap as PartCount.
    @Test("The unlabeled call form is the trapping literal, not the failable initializer")
    func unlabeledFormIsTheLiteral() async {
        await #expect(processExitsWith: .failure) {
            blackHole(CurrencyCode("nope!"))
        }
    }

    @Test("A code is written as a string, uppercased")
    func encodesAsString() throws {
        let encoded = try JSONEncoder().encode(try #require(CurrencyCode(string: "gbp")))

        #expect(String(decoding: encoded, as: UTF8.self) == "\"GBP\"")
    }

    @Test("A code reads back from a string")
    func decodesFromString() throws {
        let decoded = try JSONDecoder().decode(CurrencyCode.self, from: Data("\"GBP\"".utf8))

        #expect(decoded == "GBP")
    }

    @Test(
        "A string that is not a code is refused",
        arguments: ["\"GB\"", "\"GBPGBPGBP\"", "\"G-P\"", "\"\"", "\"£\""]
    )
    func decodingRefusesAnInvalidCode(_ json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(CurrencyCode.self, from: Data(json.utf8))
        }
    }

    @Test("Every ISO code this library knows survives a round trip")
    func roundTripsEveryISOCode() throws {
        for code in ["AED", "GBP", "JPY", "KWD", "MRU", "USD", "ZWG"] {
            let original: CurrencyCode = CurrencyCode(string: code) ?? "XXX"
            let encoded = try JSONEncoder().encode(original)

            #expect(try JSONDecoder().decode(CurrencyCode.self, from: encoded) == original)
        }
    }
}
