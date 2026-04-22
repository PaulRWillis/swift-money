import Foundation
import Testing
import SwiftMoney

@Suite("FractionalRate")
struct FractionalRateTests {

    // MARK: - init(numerator:denominator:)

    @Test("init stores 11/100 as-is")
    func initElevenHundredths() {
        let r = FractionalRate(numerator: 11, denominator: 100)
        #expect(r.numeratorValue == 11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init reduces 22/200 to 11/100")
    func initReducesFraction() {
        let r = FractionalRate(numerator: 22, denominator: 200)
        #expect(r.numeratorValue == 11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init reduces 3/6 to 1/2")
    func initReducesHalf() {
        let r = FractionalRate(numerator: 3, denominator: 6)
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 2)
    }

    @Test("init with numerator == denominator reduces to 1/1")
    func initUnitRate() {
        let r = FractionalRate(numerator: 100, denominator: 100)
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 1)
    }

    @Test("init stores negative numerator")
    func initNegativeNumerator() {
        let r = FractionalRate(numerator: -1, denominator: 10)
        #expect(r.numeratorValue == -1)
        #expect(r.denominatorValue == 10)
    }

    @Test("init reduces negative numerator (-22/200 → -11/100)")
    func initReducesNegativeFraction() {
        let r = FractionalRate(numerator: -22, denominator: 200)
        #expect(r.numeratorValue == -11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init stores zero numerator as 0/1")
    func initZeroNumerator() {
        let r = FractionalRate(numerator: 0, denominator: 100)
        #expect(r.numeratorValue == 0)
        #expect(r.denominatorValue == 1)
    }

    @Test("init accepts Int64.max numerator")
    func initInt64MaxNumerator() {
        let r = FractionalRate(numerator: .max, denominator: 1)
        #expect(r.numeratorValue == .max)
        #expect(r.denominatorValue == 1)
    }

    @Test("init traps on denominator == 0")
    func initZeroDenominatorTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = FractionalRate(numerator: 1, denominator: 0)
        }
    }

    @Test("init traps on denominator < 0")
    func initNegativeDenominatorTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = FractionalRate(numerator: 1, denominator: -1)
        }
    }

    @Test("init traps on numerator == Int64.min")
    func initInt64MinNumeratorTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = FractionalRate(numerator: .min, denominator: 1)
        }
    }

    // MARK: - init(_ decimal: Decimal)

    @Test("init from Decimal 0.11 produces 11/100")
    func initFromDecimalElevenHundredths() {
        let r = FractionalRate(Decimal(string: "0.11")!)
        #expect(r.numeratorValue == 11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init from Decimal 0.25 produces 1/4")
    func initFromDecimalQuarter() {
        let r = FractionalRate(Decimal(string: "0.25")!)
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 4)
    }

    @Test("init from Decimal 1.5 produces 3/2")
    func initFromDecimalOneAndHalf() {
        let r = FractionalRate(Decimal(string: "1.5")!)
        #expect(r.numeratorValue == 3)
        #expect(r.denominatorValue == 2)
    }

    @Test("init from Decimal 1.0 produces 1/1")
    func initFromDecimalOne() {
        let r = FractionalRate(Decimal(string: "1.0")!)
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 1)
    }

    @Test("init from Decimal 2.0 produces 2/1")
    func initFromDecimalTwo() {
        let r = FractionalRate(Decimal(string: "2.0")!)
        #expect(r.numeratorValue == 2)
        #expect(r.denominatorValue == 1)
    }

    @Test("init from Decimal 0.0 produces 0/1")
    func initFromDecimalZero() {
        let r = FractionalRate(Decimal(0))
        #expect(r.numeratorValue == 0)
        #expect(r.denominatorValue == 1)
    }

    @Test("init from Decimal -0.11 produces -11/100")
    func initFromDecimalNegative() {
        let r = FractionalRate(Decimal(string: "-0.11")!)
        #expect(r.numeratorValue == -11)
        #expect(r.denominatorValue == 100)
    }

    @Test("init from Decimal matches integer pair init for same rate")
    func initFromDecimalMatchesIntegerPair() {
        let fromDecimal = FractionalRate(Decimal(string: "0.11")!)
        let fromPair = FractionalRate(numerator: 11, denominator: 100)
        #expect(fromDecimal == fromPair)
    }

    @Test("init from Decimal preserves more than 10 decimal places (lossless)")
    func initFromDecimalHighPrecision() {
        // 0.12345678901234 = 12345678901234 / 10^14
        // GCD(12345678901234, 100_000_000_000_000) = 2, so reduces to:
        // 6172839450617 / 50_000_000_000_000
        // Old 10^10-scale approach would have rounded to 0.1234567890 (losing 4 digits).
        let r = FractionalRate(Decimal(string: "0.12345678901234")!)
        #expect(r.numeratorValue == 6172839450617)
        #expect(r.denominatorValue == 50_000_000_000_000)
    }

    @Test("init from Decimal with 11 decimal places is lossless")
    func initFromDecimalElevenPlaces() {
        // 1 / 10^11: exponent approach gives exact 1/100_000_000_000
        let r = FractionalRate(Decimal(string: "0.00000000001")!)
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 100_000_000_000)
    }

    @Test("init from Decimal traps on NaN")
    func initFromDecimalNaNTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = FractionalRate(Decimal.nan)
        }
    }

    // MARK: - ExpressibleByIntegerLiteral

    @Test("Integer literal 2 produces 2/1")
    func integerLiteralTwo() {
        let r: FractionalRate = 2
        #expect(r.numeratorValue == 2)
        #expect(r.denominatorValue == 1)
    }

    @Test("Integer literal 1 produces 1/1")
    func integerLiteralOne() {
        let r: FractionalRate = 1
        #expect(r.numeratorValue == 1)
        #expect(r.denominatorValue == 1)
    }

    // MARK: - Equatable

    @Test("Equal fractions are equal")
    func equalFractionsAreEqual() {
        let a = FractionalRate(numerator: 11, denominator: 100)
        let b = FractionalRate(numerator: 11, denominator: 100)
        #expect(a == b)
    }

    @Test("22/200 equals 11/100 after reduction")
    func reducedFractionsAreEqual() {
        let a = FractionalRate(numerator: 22, denominator: 200)
        let b = FractionalRate(numerator: 11, denominator: 100)
        #expect(a == b)
    }

    @Test("Different fractions are not equal")
    func differentFractionsAreNotEqual() {
        #expect(FractionalRate(numerator: 1, denominator: 10)
                    != FractionalRate(numerator: 1, denominator: 100))
    }

    @Test("Integer literal equals explicit 1/1 init")
    func integerLiteralEqualsExplicitInit() {
        let literal: FractionalRate = 1
        let explicit = FractionalRate(numerator: 1, denominator: 1)
        #expect(literal == explicit)
    }

    // MARK: - Hashable

    @Test("Equal rates produce the same hash")
    func equalRatesSameHash() {
        let a = FractionalRate(numerator: 22, denominator: 200)
        let b = FractionalRate(numerator: 11, denominator: 100)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("FractionalRate can be used as a Set element (22/200 and 11/100 deduplicate)")
    func usableInSet() {
        let set: Set<FractionalRate> = [
            FractionalRate(numerator: 11, denominator: 100),
            FractionalRate(numerator: 22, denominator: 200),  // duplicate after reduction
            FractionalRate(numerator: 1,  denominator: 4),
        ]
        #expect(set.count == 2)
    }

    @Test("FractionalRate can be used as a Dictionary key")
    func usableAsDictionaryKey() {
        var dict: [FractionalRate: String] = [:]
        dict[FractionalRate(numerator: 11, denominator: 100)] = "eleven percent"
        let lookupKey = FractionalRate(numerator: 22, denominator: 200)
        #expect(dict[lookupKey] == "eleven percent")
    }

    // MARK: - Comparable

    @Test("1/10 is less than 1/5")
    func compareSmaller() {
        let tenth = FractionalRate(numerator: 1, denominator: 10)
        let fifth  = FractionalRate(numerator: 1, denominator: 5)
        #expect(tenth < fifth)
        #expect(fifth > tenth)
        #expect(!(tenth < tenth))
    }

    @Test("Negative rate is less than zero rate")
    func negativeIsLessThanZero() {
        let negative = FractionalRate(numerator: -1, denominator: 10)
        let zero     = FractionalRate(numerator: 0, denominator: 1)
        #expect(negative < zero)
    }

    @Test("FractionalRates can be sorted")
    func sortable() {
        let unsorted: [FractionalRate] = [
            FractionalRate(numerator: 1, denominator: 2),
            FractionalRate(numerator: 1, denominator: 10),
            FractionalRate(numerator: 1, denominator: 4),
        ]
        let sorted = unsorted.sorted()
        #expect(sorted == [
            FractionalRate(numerator: 1, denominator: 10),
            FractionalRate(numerator: 1, denominator: 4),
            FractionalRate(numerator: 1, denominator: 2),
        ])
    }

    // MARK: - CustomStringConvertible

    @Test("description formats as numerator/denominator",
          arguments: zip(
              [
                  FractionalRate(numerator: 11, denominator: 100),
                  FractionalRate(numerator: -1, denominator: 10),
                  FractionalRate(numerator: 1,  denominator: 1),
                  FractionalRate(numerator: 0,  denominator: 1),
              ] as [FractionalRate],
              ["11/100", "-1/10", "1/1", "0/1"] as [String]
          ))
    func description(rate: FractionalRate, expected: String) {
        #expect(rate.description == expected)
    }

    // MARK: - Codable

    @Test("Encodes to JSON with numerator and denominator keys")
    func encodesToJson() throws {
        let r = FractionalRate(numerator: 11, denominator: 100)
        let data = try JSONEncoder().encode(r)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"numerator\":11"))
        #expect(json.contains("\"denominator\":100"))
    }

    @Test("Decodes from JSON")
    func decodesFromJson() throws {
        let json = #"{"numerator":11,"denominator":100}"#
        let data = try #require(json.data(using: .utf8))
        let r = try JSONDecoder().decode(FractionalRate.self, from: data)
        #expect(r == FractionalRate(numerator: 11, denominator: 100))
    }

    @Test("Round-trips through JSON")
    func roundTrips() throws {
        let original = FractionalRate(numerator: 11, denominator: 100)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FractionalRate.self, from: data)
        #expect(decoded == original)
    }

    @Test("Decoding denominator == 0 throws DecodingError")
    func decodingZeroDenominatorThrows() throws {
        let json = #"{"numerator":1,"denominator":0}"#
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(FractionalRate.self, from: data)
        }
    }

    @Test("Decoding denominator < 0 throws DecodingError")
    func decodingNegativeDenominatorThrows() throws {
        let json = #"{"numerator":1,"denominator":-1}"#
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(FractionalRate.self, from: data)
        }
    }
}
