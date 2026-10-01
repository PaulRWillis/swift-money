import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Codable Tests")
struct MoneyFormatStyleCodableTests {
    typealias Precision = NumberFormatStyleConfiguration.Precision

    private static let britishEnglish = Locale(identifier: "en_GB")

    private static let precisions: [Precision] = [
        .fractionLength(0),
        .fractionLength(2),
        .fractionLength(40),
        .fractionLength(5000),
        .fractionLength(1...3),
        .fractionLength(1..<3),
        .fractionLength(1...),
        .fractionLength(...3),
        .integerLength(2),
        .integerLength(1...3),
        .integerLength(1...),
        .integerLength(...3),
        .integerAndFractionLength(integer: 2, fraction: 3),
        .integerAndFractionLength(integer: 1000, fraction: 1000),
        .integerAndFractionLength(integerLimits: 1...2, fractionLimits: 3...),
        .integerAndFractionLength(integerLimits: ...4, fractionLimits: 1...2),
        .integerAndFractionLength(integerLimits: 2...2, fractionLimits: 1...3),
        .integerAndFractionLength(integerLimits: 1..., fractionLimits: ...2),
        .integerAndFractionLength(integerLimits: 1...3, fractionLimits: 2...2),
        .significantDigits(3),
        .significantDigits(5000),
        .significantDigits(2...4),
        .significantDigits(2...),
        .significantDigits(...4),
        .significantDigits(...999),
    ]

    // Captured from the encoder before the style read its precision itself, so a change to the shape
    // it writes shows up here as JSON that no longer decodes.
    private static let writtenPrecisions: [(json: String, precision: Precision)] = [
        (
            #"{"option":{"maxFractionalLength":2,"maxIntegerLength":null,"minFractionalLength":2,"minIntegerLength":null}}"#,
            .fractionLength(2)
        ),
        (
            #"{"option":{"maxFractionalLength":3,"maxIntegerLength":null,"minFractionalLength":1,"minIntegerLength":null}}"#,
            .fractionLength(1...3)
        ),
        (
            #"{"option":{"maxFractionalLength":null,"maxIntegerLength":null,"minFractionalLength":1,"minIntegerLength":null}}"#,
            .fractionLength(1...)
        ),
        (
            #"{"option":{"maxFractionalLength":3,"maxIntegerLength":null,"minFractionalLength":null,"minIntegerLength":null}}"#,
            .fractionLength(...3)
        ),
        (
            #"{"option":{"maxFractionalLength":null,"maxIntegerLength":2,"minFractionalLength":null,"minIntegerLength":2}}"#,
            .integerLength(2)
        ),
        (
            #"{"option":{"maxFractionalLength":3,"maxIntegerLength":2,"minFractionalLength":3,"minIntegerLength":2}}"#,
            .integerAndFractionLength(integer: 2, fraction: 3)
        ),
        (
            #"{"option":{"maxFractionalLength":null,"maxIntegerLength":2,"minFractionalLength":3,"minIntegerLength":1}}"#,
            .integerAndFractionLength(integerLimits: 1...2, fractionLimits: 3...)
        ),
        (#"{"option":{"maxSignificantDigits":3,"minSignificantDigits":3}}"#, .significantDigits(3)),
        (#"{"option":{"maxSignificantDigits":4,"minSignificantDigits":2}}"#, .significantDigits(2...4)),
        (#"{"option":{"maxSignificantDigits":null,"minSignificantDigits":2}}"#, .significantDigits(2...)),
    ]

    /// How a decoder refuses a precision, and the key it names.
    enum Refusal: Equatable, Sendable {
        /// A value that breaks a precision's rules, at the given key, or `nil` at the top level.
        case dataCorrupted(at: String?)

        /// A value of the wrong type, at the given key, or `nil` at the top level.
        case typeMismatch(at: String?)

        /// A missing key.
        case keyNotFound(String)

        /// Creates the refusal a decoding error reports, or `nil` for any other kind of error.
        ///
        /// - Parameter error: The error a decoder threw.
        init?(_ error: DecodingError) {
            switch error {
            case let .dataCorrupted(context):
                self = .dataCorrupted(at: context.codingPath.last?.stringValue)
            case let .typeMismatch(_, context):
                self = .typeMismatch(at: context.codingPath.last?.stringValue)
            case let .keyNotFound(key, _):
                self = .keyNotFound(key.stringValue)
            case .valueNotFound:
                return nil
            @unknown default:
                return nil
            }
        }
    }

    // A refusal names "option" when the option as a whole is wrong.
    private static let invalidPrecisions: [(json: String, refusal: Refusal)] = [
        (
            #"{"option":{"maxFractionalLength":1,"maxIntegerLength":null,"minFractionalLength":3,"minIntegerLength":null}}"#,
            .dataCorrupted(at: "minFractionalLength")
        ),
        (
            #"{"option":{"maxFractionalLength":null,"maxIntegerLength":1,"minFractionalLength":null,"minIntegerLength":2}}"#,
            .dataCorrupted(at: "minIntegerLength")
        ),
        (
            #"{"option":{"maxFractionalLength":-2,"maxIntegerLength":null,"minFractionalLength":-2,"minIntegerLength":null}}"#,
            .dataCorrupted(at: "minFractionalLength")
        ),
        (#"{"option":{"maxIntegerLength":-1}}"#, .dataCorrupted(at: "maxIntegerLength")),
        (
            #"{"option":{"maxFractionalLength":null,"maxIntegerLength":null,"minFractionalLength":null,"minIntegerLength":null}}"#,
            .dataCorrupted(at: "option")
        ),
        (#"{"option":{}}"#, .dataCorrupted(at: "option")),
        (#"{"option":{"minFractionalLength":"two","maxFractionalLength":2}}"#, .typeMismatch(at: "minFractionalLength")),
        // `JSONDecoder` reports a number that isn't whole as data that isn't JSON, with no key.
        (#"{"option":{"minFractionalLength":2.5,"maxFractionalLength":3}}"#, .dataCorrupted(at: nil)),
        (#"{"option":{"maxSignificantDigits":2,"minSignificantDigits":4}}"#, .dataCorrupted(at: "minSignificantDigits")),
        (#"{"option":{"maxSignificantDigits":0,"minSignificantDigits":0}}"#, .dataCorrupted(at: "minSignificantDigits")),
        (#"{"option":{"maxSignificantDigits":3,"minSignificantDigits":null}}"#, .dataCorrupted(at: "minSignificantDigits")),
        (
            #"{"option":{"minSignificantDigits":2,"maxSignificantDigits":2,"minFractionalLength":1,"maxFractionalLength":1}}"#,
            .dataCorrupted(at: "option")
        ),
        // A key whose value is null still names its family: these two pick significant digits.
        (#"{"option":{"minSignificantDigits":null,"maxSignificantDigits":null}}"#, .dataCorrupted(at: "minSignificantDigits")),
        (
            #"{"option":{"minSignificantDigits":null,"maxSignificantDigits":null,"minFractionalLength":2,"maxFractionalLength":2}}"#,
            .dataCorrupted(at: "option")
        ),
        (#"{"option":{"minIntegerLength":1,"maxIntegerLength":999}}"#, .dataCorrupted(at: "maxIntegerLength")),
        (#"{"option":{"minFractionalLength":1,"maxFractionalLength":999}}"#, .dataCorrupted(at: "maxFractionalLength")),
        (#"{"option":{"minIntegerLength":1000,"maxIntegerLength":2000}}"#, .dataCorrupted(at: "maxIntegerLength")),
        (#"{"option":{"minSignificantDigits":2,"maxSignificantDigits":999}}"#, .dataCorrupted(at: "maxSignificantDigits")),
        (#"{"option":{"minIntegerLength":1000}}"#, .dataCorrupted(at: "minIntegerLength")),
        (#"{"option":{"minFractionalLength":1000}}"#, .dataCorrupted(at: "minFractionalLength")),
        (#"{"option":{"minSignificantDigits":1000}}"#, .dataCorrupted(at: "minSignificantDigits")),
        (#"{"option":{"maxIntegerLength":1000}}"#, .dataCorrupted(at: "maxIntegerLength")),
        (#"{"option":{"maxFractionalLength":1000}}"#, .dataCorrupted(at: "maxFractionalLength")),
        (#"{"option":{"minSignificantDigits":1,"maxSignificantDigits":1000}}"#, .dataCorrupted(at: "maxSignificantDigits")),
        (#"{"option":{"minSignificantDigits":1,"maxSignificantDigits":5000}}"#, .dataCorrupted(at: "maxSignificantDigits")),
        (
            #"{"option":{"minIntegerLength":999,"maxIntegerLength":999,"minFractionalLength":1,"maxFractionalLength":3}}"#,
            .dataCorrupted(at: "maxIntegerLength")
        ),
        (
            #"{"option":{"minIntegerLength":1,"maxIntegerLength":3,"minFractionalLength":999,"maxFractionalLength":999}}"#,
            .dataCorrupted(at: "maxFractionalLength")
        ),
        (
            #"{"option":{"minIntegerLength":1,"maxIntegerLength":2,"minFractionalLength":1000}}"#,
            .dataCorrupted(at: "minFractionalLength")
        ),
        (#"{}"#, .keyNotFound("option")),
    ]

    // Each row holds a precision at the limit Foundation's range factories clamp to, the same one a
    // digit inside it, and the same one a digit past it. The decoder refuses anything past the limit.
    private static let foundationLimits: [(atLimit: Precision, inside: Precision, past: Precision)] = [
        (.integerLength(1...998), .integerLength(1...997), .integerLength(1...999)),
        (.fractionLength(1...998), .fractionLength(1...997), .fractionLength(1...999)),
        (.significantDigits(1...998), .significantDigits(1...997), .significantDigits(1...999)),
        (.significantDigits(2...998), .significantDigits(2...997), .significantDigits(2...999)),
        (.integerLength(999...), .integerLength(998...), .integerLength(1000...)),
        (.fractionLength(999...), .fractionLength(998...), .fractionLength(1000...)),
        (.significantDigits(999...), .significantDigits(998...), .significantDigits(1000...)),
        (.integerLength(...999), .integerLength(...998), .integerLength(...1000)),
        (.fractionLength(...999), .fractionLength(...998), .fractionLength(...1000)),
        (.significantDigits(...999), .significantDigits(...998), .significantDigits(...1000)),
        (
            .integerAndFractionLength(integerLimits: 998...998, fractionLimits: 1...3),
            .integerAndFractionLength(integerLimits: 997...997, fractionLimits: 1...3),
            .integerAndFractionLength(integerLimits: 999...999, fractionLimits: 1...3)
        ),
        (
            .integerAndFractionLength(integerLimits: 1...3, fractionLimits: 998...998),
            .integerAndFractionLength(integerLimits: 1...3, fractionLimits: 997...997),
            .integerAndFractionLength(integerLimits: 1...3, fractionLimits: 999...999)
        ),
        (
            .integerAndFractionLength(integerLimits: 1...2, fractionLimits: 999...),
            .integerAndFractionLength(integerLimits: 1...2, fractionLimits: 998...),
            .integerAndFractionLength(integerLimits: 1...2, fractionLimits: 1000...)
        ),
        (
            .integerAndFractionLength(integerLimits: 1...998, fractionLimits: 1...3),
            .integerAndFractionLength(integerLimits: 1...997, fractionLimits: 1...3),
            .integerAndFractionLength(integerLimits: 1...999, fractionLimits: 1...3)
        ),
        (
            .integerAndFractionLength(integerLimits: ...999, fractionLimits: 1...3),
            .integerAndFractionLength(integerLimits: ...998, fractionLimits: 1...3),
            .integerAndFractionLength(integerLimits: ...1000, fractionLimits: 1...3)
        ),
    ]

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

    @Test("A fraction-length precision survives a round trip through JSON")
    func roundTripsAFractionLengthPrecision() throws {
        let sut = GBP.FormatStyle().locale(Self.britishEnglish).precision(.fractionLength(2))

        #expect(try Self.decoded(sut) == sut)
    }

    @Test("Every precision survives a round trip through JSON", arguments: Self.precisions)
    func roundTripsEveryPrecision(precision: Precision) throws {
        let sut = GBP.FormatStyle().locale(Self.britishEnglish).precision(precision)

        #expect(try Self.decoded(sut) == sut)
    }

    @Test("Every precision survives a round trip through JSON in a runtime style", arguments: Self.precisions)
    func roundTripsEveryPrecisionInARuntimeStyle(precision: Precision) throws {
        let sut = Money.FormatStyle().locale(Self.britishEnglish).precision(precision)

        #expect(try Self.decoded(sut) == sut)
    }

    @Test("A precision is written in the shape Foundation's own precision writes")
    func writesPrecisionInFoundationsShape() throws {
        let json = try JSONEncoder().encode(
            GBP.FormatStyle().locale(Self.britishEnglish).precision(.fractionLength(2))
        )
        let style = try #require(JSONSerialization.jsonObject(with: json) as? [String: Any])
        let precision = try #require(style["precision"])
        let written = try JSONSerialization.data(withJSONObject: precision, options: .sortedKeys)

        #expect(
            String(decoding: written, as: UTF8.self)
                == #"{"option":{"maxFractionalLength":2,"maxIntegerLength":null,"minFractionalLength":2,"minIntegerLength":null}}"#
        )
    }

    @Test("JSON written before the style read its own precision still decodes", arguments: Self.writtenPrecisions)
    func decodesPreviouslyWrittenJSON(json: String, precision: Precision) throws {
        let decoded = try JSONDecoder().decode(GBP.FormatStyle.self, from: Self.styleJSON(precision: json))

        #expect(decoded == GBP.FormatStyle().locale(Self.britishEnglish).precision(precision))
    }

    @Test("A precision that leaves its unset bounds out decodes")
    func decodesAPrecisionWithoutNulls() throws {
        let json = Self.styleJSON(precision: #"{"option":{"maxFractionalLength":2,"minFractionalLength":2}}"#)

        let decoded = try JSONDecoder().decode(GBP.FormatStyle.self, from: json)

        #expect(decoded == GBP.FormatStyle().locale(Self.britishEnglish).precision(.fractionLength(2)))
    }

    @Test("An exact significant-digits count above Foundation's range limits decodes unchanged")
    func decodesAnExactSignificantDigitsCountUnchanged() throws {
        let json = Self.styleJSON(precision: #"{"option":{"maxSignificantDigits":5000,"minSignificantDigits":5000}}"#)

        let decoded = try JSONDecoder().decode(GBP.FormatStyle.self, from: json)

        #expect(decoded == GBP.FormatStyle().locale(Self.britishEnglish).precision(.significantDigits(5000)))
        #expect(decoded != GBP.FormatStyle().locale(Self.britishEnglish).precision(.significantDigits(998)))
    }

    @Test("A style written with no precision decodes with none")
    func decodesAStyleWithNoPrecision() throws {
        let decoded = try JSONDecoder().decode(GBP.FormatStyle.self, from: Self.styleJSON(precision: nil))

        #expect(decoded == GBP.FormatStyle().locale(Self.britishEnglish))
    }

    @Test("An invalid precision is refused at the key that breaks it", arguments: Self.invalidPrecisions)
    func refusesAnInvalidPrecision(json: String, refusal: Refusal) throws {
        let error = try #require(throws: DecodingError.self) {
            try JSONDecoder().decode(GBP.FormatStyle.self, from: Self.styleJSON(precision: json))
        }

        #expect(Refusal(error) == refusal, "\(error)")
    }

    @Test(
        "A precision at Foundation's limit survives a round trip through JSON",
        arguments: Self.foundationLimits.map(\.atLimit)
    )
    func roundTripsAPrecisionAtFoundationsLimit(atLimit: Precision) throws {
        let sut = GBP.FormatStyle().locale(Self.britishEnglish).precision(atLimit)

        #expect(try Self.decoded(sut) == sut)
    }

    @Test(
        "A precision below its fewest digits encodes but does not decode",
        arguments: [
            (Precision.fractionLength(-1), "minFractionalLength"),
            (Precision.significantDigits(0), "minSignificantDigits"),
        ]
    )
    func encodesAPrecisionItRefusesToDecode(precision: Precision, offendingKey: String) throws {
        let json = try JSONEncoder().encode(GBP.FormatStyle().locale(Self.britishEnglish).precision(precision))

        let error = try #require(throws: DecodingError.self) {
            try JSONDecoder().decode(GBP.FormatStyle.self, from: json)
        }

        guard case let .dataCorrupted(context) = error else {
            Issue.record("Expected DecodingError.dataCorrupted, got \(error)")
            return
        }
        #expect(context.codingPath.last?.stringValue == offendingKey)
    }

    @Test("Foundation's range factories keep a bound at the limit and clamp one past it", arguments: Self.foundationLimits)
    func pinsFoundationsLimits(atLimit: Precision, inside: Precision, past: Precision) {
        #expect(atLimit != inside)
        #expect(past == atLimit)
    }

    @Test("Foundation's own currency style cannot read back a fraction-length precision")
    func foundationCannotReadBackAFractionLengthPrecision() throws {
        // Foundation's `Precision` writes `null` for the integer lengths it did not set, then refuses
        // its own output on the way back in. Kept as a known issue so it flags once Foundation fixes
        // the defect `CodablePrecision` works around. Verified on Swift 6.3.2.
        let foundationStyle = Decimal.FormatStyle.Currency(code: "GBP", locale: Self.britishEnglish)
            .precision(.fractionLength(2))

        withKnownIssue("Foundation's Precision does not decode a fraction length") {
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

    // A British style with only its precision set, as the encoder writes it, or with no precision at all.
    private static func styleJSON(precision: String?) -> Data {
        let precisionField = precision.map { #""precision":\#($0),"# } ?? ""

        return Data(
            """
            {"decimalSeparator":{"option":0},"grouping":{"option":0},\
            "locale":{"current":0,"identifier":"en_GB"},\(precisionField)\
            "presentation":{"option":1},"roundingRule":1,\
            "sign":{"accounting":false,"negative":0,"positive":1,"zero":1}}
            """.utf8
        )
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
