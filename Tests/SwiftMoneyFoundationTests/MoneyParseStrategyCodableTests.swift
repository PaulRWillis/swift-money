import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Parse Strategy Codable Tests")
struct MoneyParseStrategyCodableTests {
    private static let britishEnglish = Locale(identifier: "en_GB")

    @Test("A typed strategy survives a round trip through JSON")
    func roundTripsATypedStrategy() throws {
        let sut = GBP.FormatStyle().locale(Self.britishEnglish).presentation(.isoCode).parseStrategy

        let decoded = try Self.decoded(sut, as: GBP.ParseStrategy.self)

        #expect(decoded == sut)
        #expect(try decoded.parse("GBP\u{00A0}4.99") == GBP(minorUnits: 4_99))
    }

    @Test("A runtime strategy survives a round trip through JSON, currency and all")
    func roundTripsARuntimeStrategy() throws {
        let sut = Money.FormatStyle().locale(Self.britishEnglish).parseStrategy(for: .bhd)

        let decoded = try Self.decoded(sut, as: Money.ParseStrategy.self)

        #expect(decoded == sut)
        #expect(try decoded.parse("BHD\u{00A0}1.234") == Money(minorUnits: 1_234, currency: .bhd))
    }

    @Test("A runtime strategy carries a currency no ISO list names")
    func roundTripsACurrencyOutsideTheISOList() throws {
        let points = customCurrency(code: "LTY", unitScale: 1)
        let sut = Money.FormatStyle().locale(Self.britishEnglish).parseStrategy(for: points)

        #expect(try Self.decoded(sut, as: Money.ParseStrategy.self) == sut)
    }

    @Test("A typed strategy refuses to read a strategy for another currency")
    func refusesAnotherCurrency() throws {
        let euros = Money.FormatStyle().locale(Self.britishEnglish).parseStrategy(for: .eur)

        #expect(throws: DecodingError.self) {
            try Self.decoded(euros, as: GBP.ParseStrategy.self)
        }
    }

    @Test("A typed strategy refuses its own code at another scale")
    func refusesItsOwnCodeAtAnotherScale() throws {
        // GBP has 100 minor units, so 1000 contradicts it. The mis-scaled currency cannot be built
        // directly, so the conflict is injected into the JSON, as it would arrive from outside.
        let json = try Self.encodedJSON(
            Money.FormatStyle().locale(Self.britishEnglish).parseStrategy(for: .gbp),
            replacing: "\"unitScale\":100",
            with: "\"unitScale\":1000"
        )

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(GBP.ParseStrategy.self, from: json)
        }
    }

    @Test("A scale no currency could have is refused")
    func refusesAScaleNoCurrencyCouldHave() throws {
        // 240, pre-decimal sterling, which keeps a factor of three and so writes no exact decimal.
        let json = try Self.encodedJSON(
            Money.FormatStyle().locale(Self.britishEnglish).parseStrategy(for: .gbp),
            replacing: "\"unitScale\":100",
            with: "\"unitScale\":240"
        )

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Money.ParseStrategy.self, from: json)
        }
    }

    private static func decoded<T: Encodable, U: Decodable>(
        _ value: T,
        as type: U.Type
    ) throws -> U {
        try JSONDecoder().decode(type, from: JSONEncoder().encode(value))
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
