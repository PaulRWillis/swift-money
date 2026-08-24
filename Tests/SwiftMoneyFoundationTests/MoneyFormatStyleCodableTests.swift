import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Codable Tests")
struct MoneyFormatStyleCodableTests {
    private static let britishEnglish = Locale(identifier: "en_GB")

    @Test("A rounding increment below one is refused, decoded data being data", arguments: [0, -5])
    func refusesARoundingIncrementBelowOne(increment: Int) throws {
        // `rounded(rule:increment:)` traps on this, a literal being a mistake in the source. A
        // decoder is handed data instead, so the same invariant has to throw here.
        let json = try Self.encodedJSON(
            GBP.FormatStyle().locale(Self.britishEnglish).rounded(increment: 25),
            replacing: "\"roundingIncrement\":25",
            with: "\"roundingIncrement\":\(increment)"
        )

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(GBP.FormatStyle.self, from: json)
        }
    }

    private static func encodedJSON(
        _ value: some Encodable,
        replacing target: String,
        with replacement: String
    ) throws -> Data {
        let encoded = try JSONEncoder().encode(value)
        let text = try #require(String(data: encoded, encoding: .utf8))

        try #require(text.contains(target), "The JSON no longer holds \(target)")

        return Data(text.replacingOccurrences(of: target, with: replacement).utf8)
    }
}
