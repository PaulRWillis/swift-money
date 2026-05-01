import Foundation
import Testing
import SwiftMoney

@Suite("Rate")
struct RateTests {

    // MARK: - init?(numerator:denominator:)

    @Test("init stores 11/100 as-is")
    func initElevenHundredths() {
        let r = Rate(numerator: 11, denominator: 100)!
        #expect(r.numeratorValue == 11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init reduces 22/200 to 11/100")
    func initReducesFraction() {
        let r = Rate(numerator: 22, denominator: 200)!
        #expect(r.numeratorValue == 11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init reduces 3/6 to 1/2")
    func initReducesHalf() {
        let r = Rate(numerator: 3, denominator: 6)!
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 2)
    }

    @Test("init with numerator == denominator reduces to 1/1")
    func initUnitRate() {
        let r = Rate(numerator: 100, denominator: 100)!
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 1)
    }

    @Test("init stores negative numerator")
    func initNegativeNumerator() {
        let r = Rate(numerator: -1, denominator: 10)!
        #expect(r.numeratorValue == -1)
        #expect(r.denominatorValue == 10)
    }

    @Test("init reduces negative numerator (-22/200 → -11/100)")
    func initReducesNegativeFraction() {
        let r = Rate(numerator: -22, denominator: 200)!
        #expect(r.numeratorValue == -11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init stores zero numerator as 0/1")
    func initZeroNumerator() {
        let r = Rate(numerator: 0, denominator: 100)!
        #expect(r.numeratorValue == 0)
        #expect(r.denominatorValue == 1)
    }

    @Test("init accepts Int64.max numerator")
    func initInt64MaxNumerator() {
        let r = Rate(numerator: .max, denominator: 1)!
        #expect(r.numeratorValue == .max)
        #expect(r.denominatorValue == 1)
    }

    @Test("init returns nil for denominator == 0")
    func initZeroDenominatorIsNil() {
        #expect(Rate(numerator: 1, denominator: 0) == nil)
    }

    @Test("init returns nil for denominator < 0")
    func initNegativeDenominatorIsNil() {
        #expect(Rate(numerator: 1, denominator: -1) == nil)
    }

    @Test("init returns nil for numerator == Int64.min")
    func initInt64MinNumeratorIsNil() {
        #expect(Rate(numerator: .min, denominator: 1) == nil)
    }

    // MARK: - init?(_ decimal: Decimal)

    @Test("init from Decimal 0.11 produces 11/100")
    func initFromDecimalElevenHundredths() {
        let r = Rate(Decimal(string: "0.11")!)!
        #expect(r.numeratorValue == 11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init from Decimal 0.25 produces 1/4")
    func initFromDecimalQuarter() {
        let r = Rate(Decimal(string: "0.25")!)!
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 4)
    }

    @Test("init from Decimal 1.5 produces 3/2")
    func initFromDecimalOneAndHalf() {
        let r = Rate(Decimal(string: "1.5")!)!
        #expect(r.numeratorValue == 3)
        #expect(r.denominatorValue == 2)
    }

    @Test("init from Decimal 1.0 produces 1/1")
    func initFromDecimalOne() {
        let r = Rate(Decimal(string: "1.0")!)!
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 1)
    }

    @Test("init from Decimal 2.0 produces 2/1")
    func initFromDecimalTwo() {
        let r = Rate(Decimal(string: "2.0")!)!
        #expect(r.numeratorValue == 2)
        #expect(r.denominatorValue == 1)
    }

    @Test("init from Decimal 0.0 produces 0/1")
    func initFromDecimalZero() {
        let r = Rate(Decimal(0))!
        #expect(r.numeratorValue == 0)
        #expect(r.denominatorValue == 1)
    }

    @Test("init from Decimal -0.11 produces -11/100")
    func initFromDecimalNegative() {
        let r = Rate(Decimal(string: "-0.11")!)!
        #expect(r.numeratorValue == -11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init from Decimal matches integer pair init for same rate")
    func initFromDecimalMatchesIntegerPair() {
        let fromDecimal = Rate(Decimal(string: "0.11")!)!
        let fromPair    = Rate(numerator: 11, denominator: 100)!
        #expect(fromDecimal == fromPair)
    }

    @Test("init from Decimal preserves more than 10 decimal places (lossless)")
    func initFromDecimalHighPrecision() {
        // 0.12345678901234 = 12345678901234 / 10^14
        // GCD(12345678901234, 100_000_000_000_000) = 2
        // reduces to 6172839450617 / 50_000_000_000_000
        let r = Rate(Decimal(string: "0.12345678901234")!)!
        #expect(r.numeratorValue == 6172839450617)
        #expect(r.denominatorValue == 50_000_000_000_000)
    }

    @Test("init from Decimal with 11 decimal places is lossless")
    func initFromDecimalElevenPlaces() {
        let r = Rate(Decimal(string: "0.00000000001")!)!
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 100_000_000_000)
    }

    @Test("init from Decimal returns nil for NaN")
    func initFromDecimalNaNIsNil() {
        #expect(Rate(Decimal.nan) == nil)
    }

    // MARK: - ExpressibleByIntegerLiteral

    @Test("Integer literal 2 produces 2/1")
    func integerLiteralTwo() {
        let r: Rate = 2
        #expect(r.numeratorValue == 2)
        #expect(r.denominatorValue == 1)
    }

    @Test("Integer literal 1 produces 1/1")
    func integerLiteralOne() {
        let r: Rate = 1
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 1)
    }

    // MARK: - Equatable

    @Test("Equal fractions are equal")
    func equalFractionsAreEqual() {
        let a = Rate(numerator: 11, denominator: 100)!
        let b = Rate(numerator: 11, denominator: 100)!
        #expect(a == b)
    }

    @Test("22/200 equals 11/100 after reduction")
    func reducedFractionsAreEqual() {
        let a = Rate(numerator: 22, denominator: 200)!
        let b = Rate(numerator: 11, denominator: 100)!
        #expect(a == b)
    }

    @Test("Different fractions are not equal")
    func differentFractionsAreNotEqual() {
        #expect(Rate(numerator: 1, denominator: 10)!
                    != Rate(numerator: 1, denominator: 100)!)
    }

    @Test("Integer literal equals explicit 1/1 init")
    func integerLiteralEqualsExplicitInit() {
        let literal: Rate = 1
        let explicit = Rate(numerator: 1, denominator: 1)!
        #expect(literal == explicit)
    }

    // MARK: - Hashable

    @Test("Equal rates produce the same hash")
    func equalRatesSameHash() {
        let a = Rate(numerator: 22, denominator: 200)!
        let b = Rate(numerator: 11, denominator: 100)!
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Rate can be used as a Set element (22/200 and 11/100 deduplicate)")
    func usableInSet() {
        let set: Set<Rate> = [
            Rate(numerator: 11, denominator: 100)!,
            Rate(numerator: 22, denominator: 200)!,
            Rate(numerator: 1,  denominator: 4)!,
        ]
        #expect(set.count == 2)
    }

    @Test("Rate can be used as a Dictionary key")
    func usableAsDictionaryKey() {
        var dict: [Rate: String] = [:]
        dict[Rate(numerator: 11, denominator: 100)!] = "eleven percent"
        let lookupKey = Rate(numerator: 22, denominator: 200)!
        #expect(dict[lookupKey] == "eleven percent")
    }

    // MARK: - Comparable

    @Test("1/10 is less than 1/5")
    func compareSmaller() {
        let tenth = Rate(numerator: 1, denominator: 10)!
        let fifth  = Rate(numerator: 1, denominator: 5)!
        #expect(tenth < fifth)
        #expect(fifth > tenth)
        #expect(!(tenth < tenth))
    }

    @Test("Negative rate is less than zero rate")
    func negativeIsLessThanZero() {
        let negative = Rate(numerator: -1, denominator: 10)!
        let zero     = Rate(numerator: 0, denominator: 1)!
        #expect(negative < zero)
    }

    @Test("Rates can be sorted")
    func sortable() {
        let unsorted: [Rate] = [
            Rate(numerator: 1, denominator: 2)!,
            Rate(numerator: 1, denominator: 10)!,
            Rate(numerator: 1, denominator: 4)!,
        ]
        let sorted = unsorted.sorted()
        #expect(sorted == [
            Rate(numerator: 1, denominator: 10)!,
            Rate(numerator: 1, denominator: 4)!,
            Rate(numerator: 1, denominator: 2)!,
        ])
    }

    // MARK: - CustomStringConvertible

    @Test("description formats as numerator/denominator",
          arguments: zip(
              [
                  Rate(numerator: 11, denominator: 100)!,
                  Rate(numerator: -1, denominator: 10)!,
                  Rate(numerator: 1,  denominator: 1)!,
                  Rate(numerator: 0,  denominator: 1)!,
              ] as [Rate],
              ["11/100", "-1/10", "1/1", "0/1"] as [String]
          ))
    func description(rate: Rate, expected: String) {
        #expect(rate.description == expected)
    }

    // MARK: - Codable

    @Test("Encodes to JSON with numerator and denominator keys")
    func encodesToJson() throws {
        let r = Rate(numerator: 11, denominator: 100)!
        let data = try JSONEncoder().encode(r)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"numerator\":11"))
        #expect(json.contains("\"denominator\":100"))
    }

    @Test("Decodes from JSON")
    func decodesFromJson() throws {
        let json = #"{"numerator":11,"denominator":100}"#
        let data = try #require(json.data(using: .utf8))
        let r = try JSONDecoder().decode(Rate.self, from: data)
        #expect(r == Rate(numerator: 11, denominator: 100)!)
    }

    @Test("Round-trips through JSON")
    func roundTrips() throws {
        let original = Rate(numerator: 11, denominator: 100)!
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Rate.self, from: data)
        #expect(decoded == original)
    }

    @Test("Decoding denominator == 0 throws DecodingError")
    func decodingZeroDenominatorThrows() throws {
        let json = #"{"numerator":1,"denominator":0}"#
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Rate.self, from: data)
        }
    }

    @Test("Decoding denominator < 0 throws DecodingError")
    func decodingNegativeDenominatorThrows() throws {
        let json = #"{"numerator":1,"denominator":-1}"#
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Rate.self, from: data)
        }
    }

    @Test("Decoding numerator == Int64.min throws DecodingError")
    func decodingMinNumeratorThrows() throws {
        let json = #"{"numerator":-9223372036854775808,"denominator":1}"#
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Rate.self, from: data)
        }
    }

    @Test("Decoding non-reduced fraction GCD-reduces on decode")
    func decodingNonReducedFraction() throws {
        let json = #"{"numerator":22,"denominator":200}"#
        let data = try #require(json.data(using: .utf8))
        let r = try JSONDecoder().decode(Rate.self, from: data)
        #expect(r == Rate(numerator: 11, denominator: 100)!)
        #expect(r.numeratorValue == 11)
        #expect(r.denominatorValue == 100)
    }

    @Test("Negative rate round-trips through JSON")
    func negativeRateRoundTrips() throws {
        let original = try #require(Rate(numerator: -1, denominator: 10))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Rate.self, from: data)
        #expect(decoded == original)
        #expect(decoded.numeratorValue == -1)
    }
}
