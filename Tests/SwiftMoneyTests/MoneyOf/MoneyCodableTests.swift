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

    @Test("A refusal says what was wrong and what to write instead")
    func errorNamesTheRemedy() throws {
        let error = #expect(throws: DecodingError.self) {
            try decoded(GBP.self, from: "\"nonsense\"")
        }

        let description = String(describing: try #require(error))

        #expect(description.contains("nonsense"))
        #expect(description.contains("GBP"))
    }

    @Test("A runtime amount's refusal names the coded form")
    func runtimeErrorNamesTheCodedForm() throws {
        let error = #expect(throws: DecodingError.self) {
            try decoded(Money.self, from: "\"4.99\"")
        }

        #expect(String(describing: try #require(error)).contains("GBP 499"))
    }
}
