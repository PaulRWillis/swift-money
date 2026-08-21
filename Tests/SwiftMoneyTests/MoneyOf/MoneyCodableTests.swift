import Foundation
import SwiftMoney
import Testing

private enum OldSterling: CurrencyType {
    static let currency = Currency(code: "OLD", unitScale: 240)
}

// Eight decimal places, so it reaches the exponent notation and the `Double` spacing that two
// decimal places never do.
private enum Bitcoin: CurrencyType {
    static let currency = Currency(code: "BTC", unitScale: 100_000_000)
}

// Fine enough to hold seventeen decimal places, and so fine that a `Double` cannot tell one of its
// smallest units from the next.
private enum Seventeen: CurrencyType {
    static let currency = Currency(code: "FIN", unitScale: 100_000_000_000_000_000)
}

private let exactNumberBound: Int64 = 1 << 52

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

    // MARK: - The field form

    @Test("Two fields are written under the keys the format names")
    func encodesAsFields() throws {
        let price = GBP(minorUnits: 4_99)

        #expect(try json(price, .fields) == #"{"amount":499,"currency":"GBP"}"#)
        #expect(try json(price, .fields(amount: .number(.majorUnits))) == #"{"amount":4.99,"currency":"GBP"}"#)
        #expect(try json(price, .fields(amount: .string(.minorUnits))) == #"{"amount":"499","currency":"GBP"}"#)
        #expect(try json(price, .fields(amount: .string(.majorUnits))) == #"{"amount":"4.99","currency":"GBP"}"#)
        #expect(
            try json(price, .fields(currencyKey: "ccy", amountKey: "value")) == #"{"ccy":"GBP","value":499}"#
        )
    }

    @Test("A runtime amount writes its own currency into the field")
    func encodesARuntimeAmountAsFields() throws {
        let price = Money(minorUnits: 499, currency: .jpy)

        #expect(try json(price, .fields) == #"{"amount":499,"currency":"JPY"}"#)
    }

    @Test(
        "An amount field reads as a number or as a string, in either units",
        arguments: [#"{"currency":"GBP","amount":499}"#,
                    #"{"currency":"GBP","amount":"499"}"#,
                    #"{"currency":"GBP","amount":"4.99"}"#]
    )
    func decodesFields(_ text: String) throws {
        #expect(try decoded(GBP.self, from: text, .fields) == GBP(minorUnits: 4_99))
        #expect(try decoded(Money.self, from: text, .fields) == Money(minorUnits: 4_99, currency: .gbp))
    }

    @Test("A currency field may be left out where the type names the currency")
    func decodesFieldsWithoutACurrency() throws {
        #expect(try decoded(GBP.self, from: #"{"amount":499}"#, .fields) == GBP(minorUnits: 4_99))
        #expect(throws: DecodingError.self) {
            try decoded(Money.self, from: #"{"amount":499}"#, .fields)
        }
    }

    @Test("Non-default keys read back")
    func decodesNonDefaultKeys() throws {
        let format = MoneyCodingFormat.fields(currencyKey: "ccy", amountKey: "value")

        #expect(try decoded(GBP.self, from: #"{"ccy":"GBP","value":499}"#, format) == GBP(minorUnits: 4_99))
    }

    @Test("Each shape reads whichever the other was configured for")
    func readsTheShapeItWasNotConfiguredFor() throws {
        let expected = GBP(minorUnits: 4_99)

        #expect(try decoded(GBP.self, from: #"{"currency":"GBP","amount":499}"#, .codedString) == expected)
        #expect(try decoded(GBP.self, from: "\"GBP 499\"", .fields) == expected)
    }

    @Test("An amount field that is neither a string nor a number reports what the coder found")
    func refusesAnAmountFieldOfTheWrongType() {
        #expect(throws: DecodingError.self) {
            try decoded(GBP.self, from: #"{"currency":"GBP","amount":true}"#, .fields)
        }
    }

    @Test("A field amount the currency cannot hold is refused, naming the currency")
    func refusesAnInexactFieldAmount() throws {
        let message = try refusalMessage {
            try decoded(GBP.self, from: #"{"currency":"GBP","amount":"4.999"}"#, .fields)
        }

        #expect(message.contains("GBP can hold exactly"))
    }

    @Test("A field currency that is not the type's own is refused")
    func refusesAMismatchedFieldCurrency() throws {
        let message = try refusalMessage {
            try decoded(GBP.self, from: #"{"currency":"USD","amount":499}"#, .fields)
        }

        #expect(message.contains("Expected GBP"))
    }

    @Test("Both shapes round trip both money types, whichever is configured")
    func roundTripsEveryShape() throws {
        let formats: [MoneyCodingFormat] = [
            .codedString,
            .codedString(.majorUnits),
            .fields,
            .fields(amount: .string(.minorUnits)),
            .fields(amount: .string(.majorUnits)),
            .fields(currencyKey: "ccy", amountKey: "value"),
        ]

        for format in formats {
            let typed = GBP(minorUnits: -4_99)
            let runtime = Money(minorUnits: 1, currency: .kwd)

            #expect(try decoder(format).decode(GBP.self, from: encoder(format).encode(typed)) == typed)
            #expect(try decoder(format).decode(Money.self, from: encoder(format).encode(runtime)) == runtime)
        }
    }

    // MARK: - The amount alone

    @Test("An amount alone is written as named, and carries no currency")
    func encodesAsAnAmountAlone() throws {
        let price = GBP(minorUnits: 4_99)

        #expect(try json(price, .amountOnly) == "499")
        #expect(try json(price, .amountOnly(.number(.majorUnits))) == "4.99")
        #expect(try json(price, .amountOnly(.string(.minorUnits))) == "\"499\"")
        #expect(try json(price, .amountOnly(.string(.majorUnits))) == "\"4.99\"")
    }

    @Test("An amount alone sits under a key belonging to the model around it")
    func roundTripsAnAmountAloneWithinAModel() throws {
        struct Product: Codable, Equatable {
            let price: GBP
        }

        let product = Product(price: GBP(minorUnits: 4_00))
        let encoded = try encoder(.amountOnly).encode(product)

        #expect(String(decoding: encoded, as: UTF8.self) == #"{"price":400}"#)
        #expect(try decoder(.amountOnly).decode(Product.self, from: encoded) == product)
    }

    @Test("A bare amount reads as the currency's smallest units, whatever is configured")
    func decodesABareAmount() throws {
        #expect(try decoded(GBP.self, from: "499", .amountOnly) == GBP(minorUnits: 4_99))
        #expect(try decoded(GBP.self, from: "499") == GBP(minorUnits: 4_99))
        #expect(try decoded(GBP.self, from: "499", .fields) == GBP(minorUnits: 4_99))
        #expect(try decoded(GBP.self, from: "-499") == GBP(minorUnits: -4_99))
    }

    @Test("A currency with no exact decimal writes its smallest units alone")
    func encodesAnAmountAloneWithoutAnExactDecimal() throws {
        let sevenPence = MoneyOf<OldSterling>(minorUnits: 7)

        #expect(try json(sevenPence, .amountOnly(.string(.majorUnits))) == "\"7\"")
    }

    @Test("A runtime amount refuses to write an amount alone, naming the remedy")
    func refusesToEncodeARuntimeAmountAlone() throws {
        let message = try encodingRefusalMessage {
            try encoder(.amountOnly).encode(Money(minorUnits: 4_99, currency: .gbp))
        }

        #expect(message.contains("does not say which currency"))
        #expect(message.contains("codedString or fields"))
    }

    @Test("A runtime amount refuses to read an amount alone, naming the remedy")
    func refusesToDecodeARuntimeAmountAlone() throws {
        let message = try refusalMessage { try decoded(Money.self, from: "499", .amountOnly) }

        #expect(message.contains("No currency named"))
        #expect(!message.contains("hold exactly"))
    }

    @Test("An amount alone round trips both spellings")
    func roundTripsAnAmountAlone() throws {
        let formats: [MoneyCodingFormat] = [
            .amountOnly,
            .amountOnly(.string(.minorUnits)),
            .amountOnly(.string(.majorUnits)),
        ]

        for format in formats {
            let typed = GBP(minorUnits: -4_99)

            #expect(try decoder(format).decode(GBP.self, from: encoder(format).encode(typed)) == typed)
        }
    }

    // MARK: - Numbers

    @Test("A number counts the units the format names, never the units it happens to be written in")
    func readsANumberInTheUnitsConfigured() throws {
        let minor = MoneyCodingFormat.amountOnly
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))

        #expect(try decoded(GBP.self, from: "400", minor) == GBP(minorUnits: 4_00))
        #expect(try decoded(GBP.self, from: "400", major) == GBP(minorUnits: 400_00))
    }

    @Test("A fraction of zero is the same number, so it reads the same either way")
    func readsAWholeNumberWrittenWithAFraction() throws {
        let minor = MoneyCodingFormat.amountOnly
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))

        #expect(try decoded(GBP.self, from: "400.00", minor) == GBP(minorUnits: 4_00))
        #expect(try decoded(GBP.self, from: "400.00", major) == GBP(minorUnits: 400_00))
    }

    @Test("A string says its own units, whatever the format names")
    func readsAStringInItsOwnUnits() throws {
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))

        #expect(try decoded(GBP.self, from: "\"4.00\"", major) == GBP(minorUnits: 4_00))
        #expect(try decoded(GBP.self, from: "\"400\"", major) == GBP(minorUnits: 400))
    }

    @Test("A fraction is refused where the number counts smallest units, and taken where it counts major")
    func readsAFractionOnlyInMajorUnits() throws {
        let message = try refusalMessage { try decoded(GBP.self, from: "4.99", .amountOnly) }

        #expect(message.contains("4.99"))
        #expect(message.contains("GBP's smallest units"))

        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))

        #expect(try decoded(GBP.self, from: "4.99", major) == GBP(minorUnits: 4_99))
    }

    @Test("A fraction is taken exactly, rather than through arithmetic that would lose a penny")
    func readsAFractionExactly() throws {
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))

        // 8.87 * 100 is 886.9999999999999 in binary, so anything multiplying would land on 886.
        #expect(try decoded(GBP.self, from: "8.87", major) == GBP(minorUnits: 8_87))
        #expect(try decoded(GBP.self, from: "0.07", major) == GBP(minorUnits: 7))
        #expect(try decoded(GBP.self, from: "-8.87", major) == GBP(minorUnits: -8_87))
    }

    @Test("Accumulated float error is refused rather than rounded away")
    func refusesAccumulatedFloatError() throws {
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))
        let message = try refusalMessage { try decoded(GBP.self, from: "0.30000000000000004", major) }

        #expect(message.contains("GBP can hold exactly"))
    }

    @Test("A currency finer than a Double can step through is refused, however few digits arrive")
    func refusesACurrencyFinerThanADoubleCanStep() throws {
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))
        let message = try refusalMessage { try decoded(MoneyOf<Seventeen>.self, from: "0.3", major) }

        #expect(message.contains("too large to cross as a number"))
    }

    @Test("A currency with no exact decimal cannot cross as a major units number at all")
    func refusesAMajorUnitsNumberWithoutAnExactDecimal() throws {
        let sevenPence = MoneyOf<OldSterling>(minorUnits: 7)
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))
        let message = try encodingRefusalMessage { try encoder(major).encode(sevenPence) }

        // Writing 7 and reading it as major units would give 1680, a wholly different amount.
        #expect(message.contains("OLD divides into no exact decimal"))
        #expect(try json(sevenPence, .amountOnly) == "7")
    }

    // MARK: - Bitcoin, at eight decimal places

    @Test(
        "Every bitcoin amount crosses as a number exactly, exponent notation included",
        arguments: [1, 2, 12_345_678, 100_000_000, 2_099_999_976_900_000] as [Int64]
    )
    func roundTripsBitcoinAsANumber(_ satoshis: Int64) throws {
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))
        let amount = MoneyOf<Bitcoin>(minorUnits: satoshis)
        let encoded = try encoder(major).encode(amount)

        #expect(try decoder(major).decode(MoneyOf<Bitcoin>.self, from: encoded) == amount)
    }

    @Test("One satoshi describes itself in exponent notation, and still reads back")
    func readsExponentNotation() throws {
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))

        #expect(Double(1e-08).description == "1e-08")
        #expect(try decoded(MoneyOf<Bitcoin>.self, from: "1e-08", major) == MoneyOf<Bitcoin>(minorUnits: 1))
        #expect(try decoded(MoneyOf<Bitcoin>.self, from: "0.00000001", major) == MoneyOf<Bitcoin>(minorUnits: 1))
    }

    // MARK: - The range a number can name

    @Test("An amount below the bound crosses as a number, and one at it does not")
    func boundsWhatCrossesAsANumber() throws {
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))
        let inside = GBP(minorUnits: exactNumberBound - 1)
        let outside = GBP(minorUnits: exactNumberBound)

        #expect(try decoder(major).decode(GBP.self, from: encoder(major).encode(inside)) == inside)

        let message = try encodingRefusalMessage { try encoder(major).encode(outside) }

        #expect(message.contains("too large to cross as a number"))
        #expect(message.contains("Send it as a string"))
    }

    @Test("An amount at the bound still crosses as a string")
    func writesABoundedAmountAsAString() throws {
        let outside = GBP(minorUnits: exactNumberBound)

        #expect(try decoded(GBP.self, from: try json(outside)) == outside)
        #expect(try json(outside, .amountOnly(.string(.majorUnits))) == "\"45035996273704.96\"")
    }

    @Test("A number past the bound is refused on the way in, rather than read as its neighbour")
    func refusesANumberPastTheBound() throws {
        let major = MoneyCodingFormat.amountOnly(.number(.majorUnits))
        let message = try refusalMessage {
            try decoded(GBP.self, from: "89319949424986.46", major)
        }

        #expect(message.contains("too large to cross as a number"))
    }

    @Test("A number never reads back as a different amount, at any scale")
    func neverReadsBackADifferentAmount() {
        // Yen at 1, sterling at 100, bitcoin at 100,000,000, and a scale with no exact decimal.
        let swept = [sweepingNumbers(JPY.self),
                     sweepingNumbers(GBP.self),
                     sweepingNumbers(MoneyOf<Bitcoin>.self),
                     sweepingNumbers(MoneyOf<Seventeen>.self),
                     sweepingNumbers(MoneyOf<OldSterling>.self)]

        // The sweep proves nothing if everything was skipped, or if nothing reached the bound.
        #expect(swept.map(\.crossed).reduce(0, +) > 40)
        #expect(swept.map(\.refused).reduce(0, +) > 0)
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

private let sweptMagnitudes: [Int64] = [0, 1, 2, 7, 99, 100, 12345, 999_999, 1_000_000_007,
                                        999_999_999_999, exactNumberBound - 1, exactNumberBound,
                                        exactNumberBound + 1, Int64.max]

// Every magnitude worth trying, written as a major units number and read back. `nil` is a refusal,
// which is always allowed; anything that crosses must come home as itself and never as a neighbour.
private func sweepingNumbers<C: CurrencyType>(_ type: MoneyOf<C>.Type) -> (crossed: Int, refused: Int) {
    let format = MoneyCodingFormat.amountOnly(.number(.majorUnits))

    let outcomes = sweptMagnitudes
        .flatMap { [MoneyOf<C>(minorUnits: $0), MoneyOf<C>(minorUnits: -$0)] }
        .map { amount in
            (try? encoder(format).encode(amount))
                .map { (try? decoder(format).decode(MoneyOf<C>.self, from: $0)) == amount }
        }

    outcomes.compactMap { $0 }.forEach { #expect($0) }

    return (outcomes.compactMap { $0 }.count, outcomes.filter { $0 == nil }.count)
}

private func encodingRefusalMessage(_ encode: () throws -> Data) throws -> String {
    let error = #expect(throws: EncodingError.self) { _ = try encode() }

    guard case let .invalidValue(_, context) = try #require(error) else {
        Issue.record("Expected an invalidValue error")

        return ""
    }

    return context.debugDescription
}

private func refusalMessage(_ decode: () throws -> some Decodable) throws -> String {
    let error = #expect(throws: DecodingError.self) { _ = try decode() }

    guard case let .dataCorrupted(context) = try #require(error) else {
        Issue.record("Expected a dataCorrupted error")

        return ""
    }

    return context.debugDescription
}
