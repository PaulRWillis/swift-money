import Foundation
import SwiftMoney
import SwiftMoneySerialization
import Testing

/// A test currency backed by the real ISO 4217 code "KWD"
/// (Kuwaiti Dinar), which has 1000 fils to the dinar.
///
/// Used in localisation tests to exercise 3-decimal-place currencies.
/// Using the real ISO code ensures Foundation's formatter renders a
/// recognisable symbol and the fidelity comparison is meaningful.
enum TestKWD: Currency {
    static let code: CurrencyCode = "KWD"
    static let minimalQuantisation: MinimalQuantisation = 1000
}

@Suite("Money - Codable: .object(.minorUnits) strategy")
struct Money_Codable_Object_String_StrategyTests {

    // MARK: Currency mismatch

    @Test("object: currency mismatch throws DecodingError")
    func objectCurrencyMismatch() throws {
        let json = try #require(#"{"currencyCode":"USD","amount":1.25}"#.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(.majorUnits)
        #expect(throws: DecodingError.self) {
            try decoder.decode(Money<GBP>.self, from: json)
        }
    }

    @Test("object: decoding from JSON with known values is correct")
    func objectDecoding() throws {
        let json = try #require(#"{"currencyCode":"GBP","amount":1.25}"#.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .object(.majorUnits)
        let decoded = try decoder.decode(Money<GBP>.self, from: json)
        #expect(decoded.minorUnits == 125)
    }
}
