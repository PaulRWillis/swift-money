import Foundation
import SwiftMoney
import Testing

private enum OldSterling: CurrencyType {
    static let currency = Currency(code: "OLD", unitScale: 240)
}

// Keys are sorted because `JSONEncoder` does not otherwise fix their order, and a test asserting
// the whole of an object's JSON then passes about five times in six.
private func encoder(_ format: MoneyCodingFormat? = nil) -> JSONEncoder {
    let encoder = JSONEncoder()

    encoder.outputFormatting = .sortedKeys

    if let format {
        encoder.userInfo[.moneyCodingFormat] = format
    }

    return encoder
}

private func decoder(_ format: MoneyCodingFormat? = nil) -> JSONDecoder {
    let decoder = JSONDecoder()

    if let format {
        decoder.userInfo[.moneyCodingFormat] = format
    }

    return decoder
}

private func json<T: Encodable>(_ value: T, _ format: MoneyCodingFormat? = nil) throws -> String {
    String(decoding: try encoder(format).encode(value), as: UTF8.self)
}

private func decoded<T: Decodable>(
    _ type: T.Type,
    from text: String,
    _ format: MoneyCodingFormat? = nil
) throws -> T {
    try decoder(format).decode(type, from: Data(text.utf8))
}

@Suite("Money Codable Tests")
struct MoneyCodableTests {

    // MARK: - Writing

    @Test("An amount is written as its code and its smallest units")
    func encodesAsACodedString() throws {
        #expect(try json(GBP(minorUnits: 4_99)) == "\"GBP 499\"")
        #expect(try json(Money(minorUnits: 4_99, currency: .gbp)) == "\"GBP 499\"")
        #expect(try json(JPY(minorUnits: 499)) == "\"JPY 499\"")
    }

    @Test("Major units are written where the encoder asks for them")
    func encodesInMajorUnits() throws {
        #expect(try json(GBP(minorUnits: 4_99), .codedString(.majorUnits)) == "\"GBP 4.99\"")
        #expect(try json(Money(minorUnits: 1, currency: .kwd), .codedString(.majorUnits)) == "\"KWD 0.001\"")
    }

    @Test("A currency with no exact decimal writes its smallest units either way")
    func encodesACurrencyWithoutAnExactDecimal() throws {
        let sevenPence = MoneyOf<OldSterling>(minorUnits: 7)

        #expect(try json(sevenPence) == "\"OLD 7\"")
        #expect(try json(sevenPence, .codedString(.majorUnits)) == "\"OLD 7\"")
    }

    // MARK: - Reading

    @Test(
        "A typed amount reads either spelling, with or without its code",
        arguments: ["\"GBP 499\"", "\"GBP 4.99\"", "\"499\"", "\"4.99\""]
    )
    func decodesATypedAmount(_ text: String) throws {
        #expect(try decoded(GBP.self, from: text) == GBP(minorUnits: 4_99))
    }

    @Test("A runtime amount reads either spelling, and needs the code")
    func decodesARuntimeAmount() throws {
        let expected = Money(minorUnits: 4_99, currency: .gbp)

        #expect(try decoded(Money.self, from: "\"GBP 499\"") == expected)
        #expect(try decoded(Money.self, from: "\"GBP 4.99\"") == expected)
        #expect(throws: DecodingError.self) { try decoded(Money.self, from: "\"4.99\"") }
    }

    @Test("A code that is not the type's own is refused")
    func refusesAMismatchedCode() {
        #expect(throws: DecodingError.self) { try decoded(GBP.self, from: "\"USD 4.99\"") }
    }

    @Test("A code outside ISO 4217 does not resolve for a runtime amount")
    func refusesAnUnknownCode() {
        #expect(throws: DecodingError.self) { try decoded(Money.self, from: "\"LTY 250\"") }
    }

    @Test(
        "An amount finer than the currency divides is refused rather than rounded",
        arguments: ["\"GBP 4.999\"", "\"4.999\""]
    )
    func refusesExcessPrecision(_ text: String) {
        #expect(throws: DecodingError.self) { try decoded(GBP.self, from: text) }
    }

    @Test("What the encoder was told to write does not narrow what the decoder reads")
    func readsEitherSpellingWhateverIsConfigured() throws {
        let major = MoneyCodingFormat.codedString(.majorUnits)

        #expect(try decoded(GBP.self, from: "\"GBP 499\"", major) == GBP(minorUnits: 4_99))
        #expect(try decoded(GBP.self, from: "\"GBP 4.99\"", .codedString) == GBP(minorUnits: 4_99))
    }

    // MARK: - Round trip

    @Test("Every amount this library writes, it reads back")
    func roundTrips() throws {
        let amounts: [Money] = [
            Money(minorUnits: 4_99, currency: .gbp),
            Money(minorUnits: -4_99, currency: .gbp),
            Money(minorUnits: 0, currency: .gbp),
            Money(minorUnits: 499, currency: .jpy),
            Money(minorUnits: 1, currency: .kwd),
            Money(minorUnits: Int64.max, currency: .gbp),
            Money(minorUnits: Int64.min, currency: .gbp),
        ]

        for format in [MoneyCodingFormat.codedString, .codedString(.majorUnits)] {
            for amount in amounts {
                let encoded = try encoder(format).encode(amount)

                #expect(try decoder(format).decode(Money.self, from: encoded) == amount)
            }
        }
    }

    @Test("A custom currency round trips through the type that names it")
    func roundTripsACustomCurrency() throws {
        let sevenPence = MoneyOf<OldSterling>(minorUnits: 7)
        let encoded = try encoder().encode(sevenPence)

        #expect(try decoder().decode(MoneyOf<OldSterling>.self, from: encoded) == sevenPence)
    }

    @Test("An amount sits inside a larger model")
    func decodesWithinAModel() throws {
        struct Product: Codable, Equatable {
            let name: String
            let price: GBP
        }

        let product = Product(name: "Tea", price: GBP(minorUnits: 4_99))
        let encoded = try encoder().encode(product)

        #expect(String(decoding: encoded, as: UTF8.self) == #"{"name":"Tea","price":"GBP 499"}"#)
        #expect(try decoder().decode(Product.self, from: encoded) == product)
    }

    // MARK: - Errors

    // Three failures with three remedies. A caller told to write fewer decimals when their currency
    // is the problem is sent the wrong way, so each says which thing went wrong.

    @Test("An amount the currency cannot hold says so, and names the currency")
    func refusalForAnInexactAmount() throws {
        let message = try refusalMessage { try decoded(GBP.self, from: "\"4.999\"") }

        #expect(message.contains("4.999"))
        #expect(message.contains("GBP can hold exactly"))
    }

    @Test("A runtime amount names the currency it resolved, rather than saying 'its currency'")
    func refusalForAnInexactRuntimeAmount() throws {
        let message = try refusalMessage { try decoded(Money.self, from: "\"GBP 4.999\"") }

        #expect(message.contains("GBP can hold exactly"))
    }

    @Test("A code the runtime type cannot resolve says it is unknown, not that the amount is wrong")
    func refusalForAnUnknownCode() throws {
        let message = try refusalMessage { try decoded(Money.self, from: "\"LTY 250\"") }

        #expect(message.contains("Unknown currency code \"LTY\""))
        #expect(!message.contains("hold exactly"))
    }

    @Test("A code that is not the type's own names both currencies")
    func refusalForAMismatchedCode() throws {
        let message = try refusalMessage { try decoded(GBP.self, from: "\"USD 4.99\"") }

        #expect(message.contains("Expected GBP"))
        #expect(message.contains("\"USD\""))
    }

    @Test("An amount with no currency at all says that, rather than blaming the digits")
    func refusalForAnUnnamedCurrency() throws {
        let message = try refusalMessage { try decoded(Money.self, from: "\"4.99\"") }

        #expect(message.contains("No currency named"))
        #expect(!message.contains("hold exactly"))
    }
}

private func refusalMessage(_ decode: () throws -> some Decodable) throws -> String {
    let error = #expect(throws: DecodingError.self) { _ = try decode() }

    guard case let .dataCorrupted(context) = try #require(error) else {
        Issue.record("Expected a dataCorrupted error")

        return ""
    }

    return context.debugDescription
}
