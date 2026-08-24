import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Codable Tests")
struct MoneyFormatStyleCodableTests {
    private static let britishEnglish = Locale(identifier: "en_GB")

    @Test("A default style survives a round trip through JSON")
    func roundTripsADefaultStyle() throws {
        let sut = GBP.FormatStyle().locale(Self.britishEnglish)

        #expect(try Self.decoded(sut) == sut)
    }

    @Test("Every option a style carries survives a round trip through JSON")
    func roundTripsEveryOption() throws {
        let sut = GBP.FormatStyle()
            .locale(Self.britishEnglish)
            .presentation(.isoCode)
            .grouping(.never)
            .sign(strategy: .always())
            .decimalSeparator(strategy: .always)
            .precision(.significantDigits(3))
            .rounded(rule: .down, increment: 25)

        let decoded = try Self.decoded(sut)

        #expect(decoded == sut)
        #expect(decoded.format(GBP(minorUnits: 1_234_56)) == sut.format(GBP(minorUnits: 1_234_56)))
    }

    @Test("A runtime style survives a round trip through JSON")
    func roundTripsARuntimeStyle() throws {
        let sut = Money.FormatStyle().locale(Self.britishEnglish).presentation(.fullName)

        #expect(try Self.decoded(sut) == sut)
    }

    @Test("A fraction-length precision cannot be read back, as Foundation's own style cannot")
    func cannotReadBackAFractionLengthPrecision() throws {
        // Foundation writes `null` for the integer lengths it did not set, then refuses its own
        // output on the way back in. Recorded rather than hidden: `MoneyOf.FormatStyle` stores
        // Foundation's `Precision` and can only inherit the defect. Verified on Swift 6.3.2.
        let sut = GBP.FormatStyle().locale(Self.britishEnglish).precision(.fractionLength(2))

        withKnownIssue("Foundation's Precision does not decode a fraction length") {
            let decoded = try Self.decoded(sut)

            #expect(decoded == sut)
        }

        // The same JSON that our style cannot read back, Foundation cannot read back either.
        let foundationStyle = Decimal.FormatStyle.Currency(code: "GBP", locale: Self.britishEnglish)
            .precision(.fractionLength(2))

        withKnownIssue("Foundation's own currency style has the same defect") {
            let decoded = try Self.decoded(foundationStyle)

            #expect(decoded == foundationStyle)
        }
    }

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

    private static func decoded<T: Codable>(_ value: T) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
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
