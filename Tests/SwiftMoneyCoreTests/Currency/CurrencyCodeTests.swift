import Foundation
import SwiftMoneyCore
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

    @Test(
        "A code survives a round trip through its compact packing",
        arguments: [
            "GBP",       // three, the shortest
            "USD",
            "BTC",
            "USDT",      // four
            "MATIC",     // five
            "1INCH",     // leading digit
            "401K",
            "SAFEMOON",  // eight, the longest
            "ABCDEFGH",  // eight letters
            "12345678",  // eight digits
        ]
    )
    func roundTripsThroughCompactPacking(_ raw: String) throws {
        let code = try #require(CurrencyCode(string: raw))

        #expect(CurrencyCode(compactValue: code.compactValue) == code)
    }

    @Test(
        "A code packs six bits per character, first character highest, left aligned in eight slots",
        arguments: [
            ("GBP", 0b000111_000010_010000_000000_000000_000000_000000_000000),
            ("USDT", 0b010101_010011_000100_010100_000000_000000_000000_000000),
            ("1INCH", 0b011100_001001_001110_000011_001000_000000_000000_000000),
            ("SAFEMOON", 0b010011_000001_000110_000101_001101_001111_001111_001110),
            ("99999999", 0b100100_100100_100100_100100_100100_100100_100100_100100),
        ] as [(String, UInt64)]
    )
    func packsEachCharacterIntoItsSlot(_ raw: String, _ word: UInt64) throws {
        let code = try #require(CurrencyCode(string: raw))

        #expect(code.compactValue == word)
        #expect(CurrencyCode(compactValue: word) == code)
    }

    @Test(
        "A compact word that is not a valid code is refused",
        arguments: [
            0,                                                          // no characters at all
            0b000001_000000_000000_000000_000000_000000_000000_000000,  // one character, fewer than three
            0b000001_000010_000000_000000_000000_000000_000000_000000,  // two characters
            0b111111_000000_000000_000000_000000_000000_000000_000000,  // 63, past the 36 that map to a character
            0b100101_000001_000001_000000_000000_000000_000000_000000,  // 37, one past the last digit
        ] as [UInt64]
    )
    func refusesAnInvalidCompactWord(_ word: UInt64) {
        #expect(CurrencyCode(compactValue: word) == nil)
    }

    @Test(
        "A compact word with a character after an empty slot is refused",
        arguments: [
            0b000111_000010_010000_000000_000000_000000_000000_000001,  // "GBP", then "A" in the last slot
            0b000111_000010_010000_000000_000001_000000_000000_000000,  // "GBP", one empty slot, then "A"
        ] as [UInt64]
    )
    func refusesACharacterAfterAnEmptySlot(_ word: UInt64) {
        #expect(CurrencyCode(compactValue: word) == nil)
    }

    @Test(
        "A compact word with a bit set above its eight slots is refused",
        arguments: [
            0b1_000111_000010_010000_000000_000000_000000_000000_000000,                    // "GBP", plus bit 48
            0b1_000_000000_000000_000111_000010_010000_000000_000000_000000_000000_000000,  // "GBP", plus bit 63
            0b1_010011_000001_000110_000101_001101_001111_001111_001110,                    // "SAFEMOON", plus bit 48
        ] as [UInt64]
    )
    func refusesABitAboveTheSlots(_ word: UInt64) {
        #expect(CurrencyCode(compactValue: word) == nil)
    }

    @Test(
        "A three-character code's value is its characters, first highest",
        arguments: [
            ("GBP", 0b000111_000010_010000),
            ("EUR", 0b000101_010101_010010),
            ("999", 0b100100_100100_100100),
        ] as [(String, UInt64)]
    )
    func threeCharacterValue(_ raw: String, _ value: UInt64) throws {
        #expect(try #require(CurrencyCode(string: raw)).threeCharacterValue == value)
    }

    @Test("A code longer than three characters has no three-character value")
    func longerCodeHasNoThreeCharacterValue() throws {
        #expect(try #require(CurrencyCode(string: "USDT")).threeCharacterValue == nil)
    }
}
