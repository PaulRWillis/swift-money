import Foundation
import Testing
import SwiftMoney

@Suite("CurrencyCode")
struct CurrencyCodeTests {

    // MARK: - Initialisation

    @Test("init accepts a non-empty string")
    func initNonEmpty() {
        let code = CurrencyCode("GBP")
        #expect(code.stringValue == "GBP")
    }

    @Test("init accepts a single-character string")
    func initSingleChar() {
        let code = CurrencyCode("X")
        #expect(code.stringValue == "X")
    }

    @Test("init accepts ISO codes")
    func initIsoCodes() {
        #expect(CurrencyCode("EUR").stringValue == "EUR")
        #expect(CurrencyCode("USD").stringValue == "USD")
        #expect(CurrencyCode("JPY").stringValue == "JPY")
    }

    @Test("init accepts crypto codes")
    func initCryptoCodes() {
        #expect(CurrencyCode("BTC").stringValue == "BTC")
        #expect(CurrencyCode("SAT").stringValue == "SAT")
    }

    @Test("init accepts in-app currency codes")
    func initInAppCodes() {
        #expect(CurrencyCode("GEMS").stringValue == "GEMS")
        #expect(CurrencyCode("TST_100").stringValue == "TST_100")
    }

    @Test("init traps on empty string")
    func initEmptyStringTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = CurrencyCode("")
        }
    }

    // MARK: - StringLiteral

    @Test("ExpressibleByStringLiteral produces correct value")
    func stringLiteral() {
        let code: CurrencyCode = "GBP"
        #expect(code.stringValue == "GBP")
    }

    // MARK: - String conversion

    @Test("String init from CurrencyCode produces correct string")
    func stringInitFromCurrencyCode() {
        let code = CurrencyCode("GBP")
        #expect(String(code) == "GBP")
    }

    @Test("String(code) equals code.stringValue")
    func stringInitEqualsStringValue() {
        let code = CurrencyCode("EUR")
        #expect(String(code) == code.stringValue)
    }

    // MARK: - Equatable

    @Test("Equal codes compare as equal")
    func equalCodesAreEqual() {
        let a = CurrencyCode("GBP")
        let b = CurrencyCode("GBP")
        #expect(a == b)
    }

    @Test("Different codes compare as not equal")
    func differentCodesNotEqual() {
        #expect(CurrencyCode("GBP") != CurrencyCode("EUR"))
    }

    @Test("Code equals string-literal form")
    func codeEqualsStringLiteral() {
        let code = CurrencyCode("GBP")
        let literal: CurrencyCode = "GBP"
        #expect(code == literal)
    }

    // MARK: - Hashable

    @Test("Equal codes produce the same hash")
    func equalCodesSameHash() {
        let a = CurrencyCode("GBP")
        let b = CurrencyCode("GBP")
        #expect(a.hashValue == b.hashValue)
    }

    @Test("CurrencyCode can be used as a Set element")
    func usableInSet() {
        let gbp: CurrencyCode = "GBP"
        let duplicateGbp: CurrencyCode = "GBP"
        let eur: CurrencyCode = "EUR"
        let set: Set<CurrencyCode> = [gbp, duplicateGbp, eur]
        #expect(set.count == 2)
    }

    @Test("CurrencyCode can be used as a Dictionary key")
    func usableAsDictionaryKey() {
        let key: CurrencyCode = "GBP"
        var dict: [CurrencyCode: Int] = [:]
        dict[key] = 42
        #expect(dict["GBP"] == 42)
    }

    // MARK: - Comparable

    @Test("Codes with earlier lexicographic order compare as less-than")
    func comparableLessThan() {
        #expect(CurrencyCode("EUR") < CurrencyCode("GBP"))
    }

    @Test("Codes with later lexicographic order compare as greater-than")
    func comparableGreaterThan() {
        #expect(CurrencyCode("GBP") > CurrencyCode("EUR"))
    }

    @Test("Equal codes are neither less-than nor greater-than")
    func comparableEqual() {
        let a: CurrencyCode = "GBP"
        let b: CurrencyCode = "GBP"
        #expect(!(a < b))
        #expect(!(a > b))
    }

    @Test("sorted() on an array of codes is lexicographically ordered")
    func sortedIsLexicographic() {
        let codes: [CurrencyCode] = ["USD", "GBP", "BTC", "EUR"]
        let sorted = codes.sorted()
        #expect(sorted == ["BTC", "EUR", "GBP", "USD"])
    }

    // MARK: - CustomStringConvertible

    @Test("description equals stringValue")
    func descriptionEqualsStringValue() {
        let code = CurrencyCode("GBP")
        #expect(code.description == code.stringValue)
    }

    @Test("description equals the original string")
    func descriptionEqualsOriginalString() {
        #expect(CurrencyCode("EUR").description == "EUR")
    }

    // MARK: - Codable

    @Test("Encodes to a JSON string")
    func encodesToJsonString() throws {
        let code = CurrencyCode("GBP")
        let data = try JSONEncoder().encode(code)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json == #""GBP""#)
    }

    @Test("Decodes from a JSON string")
    func decodesFromJsonString() throws {
        let json = #""GBP""#
        let data = try #require(json.data(using: .utf8))
        let code = try JSONDecoder().decode(CurrencyCode.self, from: data)
        #expect(code == CurrencyCode("GBP"))
    }

    @Test("Round-trips through JSON")
    func roundTrips() throws {
        let original = CurrencyCode("TST_100")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CurrencyCode.self, from: data)
        #expect(decoded == original)
    }

    @Test("Decoding an empty string throws")
    func decodingEmptyStringThrows() throws {
        let json = #""""#
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(CurrencyCode.self, from: data)
        }
    }
}
