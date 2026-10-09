import Foundation
import SwiftMoneyCore
import Testing

// A decimal text and the value it parses to, or nil when it isn't a decimal integer that fits.
private struct ParseCase: Sendable, CustomTestStringConvertible {
    let text: String
    let expected: Int128Words?

    var testDescription: String {
        "\"\(text)\""
    }
}

// A value, a digit to append, and the result, or nil when appending it overflows.
private struct DigitCase: Sendable, CustomTestStringConvertible {
    let value: UInt128Words
    let digit: UInt8
    let expected: UInt128Words?

    var testDescription: String {
        "\(value) then \(digit)"
    }
}

// A value and the `Double` nearest it, written in hexadecimal so each bit of the result is visible.
private struct DoubleCase: Sendable, CustomTestStringConvertible {
    let name: String
    let value: Int128Words
    let expected: Double

    var testDescription: String {
        name
    }
}

private let parseCases: [ParseCase] = [
    ParseCase(text: "0", expected: 0),
    ParseCase(text: "-0", expected: 0),
    ParseCase(text: "+5", expected: 5),
    ParseCase(text: "-42", expected: -42),
    ParseCase(text: "18446744073709551616", expected: Int128Words(bitPattern: UInt128Words(high: 1, low: 0))),
    ParseCase(text: "170141183460469231731687303715884105727", expected: .max),
    ParseCase(text: "-170141183460469231731687303715884105728", expected: .min),
    ParseCase(text: "170141183460469231731687303715884105728", expected: nil),
    ParseCase(text: "-170141183460469231731687303715884105729", expected: nil),
    ParseCase(text: "340282366920938463463374607431768211456", expected: nil),
    ParseCase(text: "", expected: nil),
    ParseCase(text: "-", expected: nil),
    ParseCase(text: "+", expected: nil),
    ParseCase(text: "+-1", expected: nil),
    ParseCase(text: " 1", expected: nil),
    ParseCase(text: "1.5", expected: nil),
    ParseCase(text: "1_000", expected: nil),
    ParseCase(text: "١", expected: nil),
]

private let digitCases: [DigitCase] = [
    DigitCase(value: 12, digit: 3, expected: 123),
    DigitCase(value: UInt128Words(high: 0, low: .max), digit: 9, expected: UInt128Words(high: 9, low: .max)),
    DigitCase(value: UInt128Words(high: 1, low: 0), digit: 0, expected: UInt128Words(high: 10, low: 0)),
    DigitCase(
        value: UInt128Words(high: 0, low: 0x1999_9999_9999_9999),
        digit: 9,
        expected: UInt128Words(high: 1, low: 3)
    ),
    DigitCase(
        value: UInt128Words(high: 0x1999_9999_9999_9999, low: 0x9999_9999_9999_9999),
        digit: 5,
        expected: .max
    ),
    DigitCase(value: UInt128Words(high: 0x1999_9999_9999_9999, low: 0x9999_9999_9999_9999), digit: 6, expected: nil),
    DigitCase(value: UInt128Words(high: 0x1999_9999_9999_9999, low: 0x9999_9999_9999_999A), digit: 0, expected: nil),
    DigitCase(value: UInt128Words(high: 0x2000_0000_0000_0000, low: 0), digit: 0, expected: nil),
]

private let doubleCases: [DoubleCase] = [
    DoubleCase(name: "one word, a tie", value: Int128Words(bitPattern: UInt128Words(high: 0, low: 1 << 53 | 1)), expected: 0x1p53),
    DoubleCase(name: "two words, a tie to even below", value: Int128Words(bitPattern: UInt128Words(high: 1 << 53 | 1, low: 0)), expected: 0x1p117),
    DoubleCase(name: "two words, just above a tie", value: Int128Words(bitPattern: UInt128Words(high: 1 << 53 | 1, low: 1)), expected: 0x1.0000000000001p117),
    DoubleCase(name: "two words, a tie to even above", value: Int128Words(bitPattern: UInt128Words(high: 1 << 53 | 3, low: 0)), expected: 0x1.0000000000002p117),
    DoubleCase(name: "negative, a tie to even", value: -Int128Words(bitPattern: UInt128Words(high: 1 << 53 | 1, low: 0)), expected: -0x1p117),
    DoubleCase(name: "the largest value", value: .max, expected: 0x1p127),
    DoubleCase(name: "the smallest value", value: .min, expected: -0x1p127),
    DoubleCase(name: "zero", value: 0, expected: 0),
]

@Suite("Int128Words Tests")
struct Int128WordsTests {

    @Test("A literal fills both words in two's complement")
    func literalFillsBothWords() {
        let minusOne: Int128Words = -1
        let pastOneWord: Int128Words = 18_446_744_073_709_551_616
        let largest: Int128Words = 170_141_183_460_469_231_731_687_303_715_884_105_727
        let smallest: Int128Words = -170_141_183_460_469_231_731_687_303_715_884_105_728

        #expect(UInt128Words(bitPattern: minusOne) == .max)
        #expect(UInt128Words(bitPattern: pastOneWord) == UInt128Words(high: 1, low: 0))
        #expect(largest == .max)
        #expect(smallest == .min)
    }

    @Test("The largest and smallest values")
    func largestAndSmallest() {
        #expect(UInt128Words(bitPattern: .max) == UInt128Words(high: 0x7FFF_FFFF_FFFF_FFFF, low: .max))
        #expect(UInt128Words(bitPattern: .min) == UInt128Words(high: 0x8000_0000_0000_0000, low: 0))
    }

    @Test("An Int64 is sign-extended into the high word")
    func int64IsSignExtended() {
        #expect(UInt128Words(bitPattern: Int128Words(Int64.min)) == UInt128Words(high: .max, low: 0x8000_0000_0000_0000))
        #expect(UInt128Words(bitPattern: Int128Words(Int64.max)) == UInt128Words(high: 0, low: 0x7FFF_FFFF_FFFF_FFFF))
    }

    @Test("Converting exactly accepts any integer that fits")
    func convertingExactly() {
        #expect(Int128Words(exactly: UInt64.max) == Int128Words(bitPattern: UInt128Words(high: 0, low: .max)))
        #expect(Int128Words(exactly: Int8(-1)) == -1)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Converting exactly rejects a wider integer that doesn't fit")
    func convertingExactlyRejectsWider() {
        #expect(Int128Words(exactly: Int128.min) == .min)
        #expect(Int128Words(exactly: UInt128(Int128.max)) == .max)
        #expect(Int128Words(exactly: UInt128(Int128.max) + 1) == nil)
    }

    @Test("Converting exactly to Int64 needs the high word to be the low word's sign")
    func convertingExactlyToInt64() {
        #expect(Int64(exactly: Int128Words(bitPattern: UInt128Words(high: .max, low: 0x8000_0000_0000_0000))) == .min)
        #expect(Int64(exactly: Int128Words(bitPattern: UInt128Words(high: 0, low: 0x8000_0000_0000_0000))) == nil)
        #expect(Int64(exactly: Int128Words(bitPattern: UInt128Words(high: .max, low: 0x7FFF_FFFF_FFFF_FFFF))) == nil)
    }

    @Test("Order follows the signed value")
    func orderFollowsTheSignedValue() {
        #expect(Int128Words(-1) < 0)
        #expect(Int128Words.min < .max)
        #expect(Int128Words(bitPattern: UInt128Words(high: .max, low: 0)) < -1)
        #expect(Int128Words(bitPattern: UInt128Words(high: 0, low: .max)) < Int128Words(bitPattern: UInt128Words(high: 1, low: 0)))
    }

    @Test("The magnitude of the smallest value is two to the 127")
    func magnitudeOfTheSmallest() {
        #expect(Int128Words.min.magnitude == UInt128Words(high: 0x8000_0000_0000_0000, low: 0))
        #expect(Int128Words(-1).magnitude == 1)
    }

    @Test("The sign is negative below zero only")
    func signBelowZero() {
        #expect(Sign(of: Int128Words(-1)) == .negative)
        #expect(Sign(of: Int128Words.min) == .negative)
        #expect(Sign(of: Int128Words(0)) == .positive)
        #expect(Sign(of: Int128Words.max) == .positive)
    }

    @Test("Rebuilding from a magnitude takes the smallest value directly")
    func rebuildingFromAMagnitude() {
        let twoToThe127 = UInt128Words(high: 0x8000_0000_0000_0000, low: 0)

        #expect(Int128Words(magnitude: twoToThe127, sign: .negative) == .min)
        #expect(Int128Words(magnitude: twoToThe127, sign: .positive) == nil)
        #expect(Int128Words(magnitude: UInt128Words(high: 0x8000_0000_0000_0000, low: 1), sign: .negative) == nil)
        #expect(Int128Words(magnitude: 0, sign: .negative) == 0)
    }

    @Test("Adding and subtracting overflow at the ends of the range")
    func addingAndSubtractingOverflow() {
        let pastTheTop = Int128Words.max.addingReportingOverflow(1)
        let pastTheBottom = Int128Words.min.addingReportingOverflow(-1)
        let belowTheBottom = Int128Words.min.subtractingReportingOverflow(1)
        let negatingTheBottom = Int128Words(0).subtractingReportingOverflow(.min)

        #expect(pastTheTop.partialValue == .min)
        #expect(pastTheTop.overflow)
        #expect(pastTheBottom.partialValue == .max)
        #expect(pastTheBottom.overflow)
        #expect(belowTheBottom.partialValue == .max)
        #expect(belowTheBottom.overflow)
        #expect(negatingTheBottom.partialValue == .min)
        #expect(negatingTheBottom.overflow)
        #expect(Int128Words(-1) + 1 == 0)
        #expect(Int128Words(-1) - 1 == -2)
    }

    @Test("Multiplying overflows past either end of the range")
    func multiplyingOverflows() {
        let twoToThe63 = Int128Words(bitPattern: UInt128Words(high: 0, low: 0x8000_0000_0000_0000))
        let twoToThe64 = Int128Words(bitPattern: UInt128Words(high: 1, low: 0))
        let negatedSmallest = Int128Words.min.multipliedReportingOverflow(by: Int128Words(-1))
        let twoToThe127 = twoToThe63.multipliedReportingOverflow(by: twoToThe64)
        let smallest = (-twoToThe63).multipliedReportingOverflow(by: twoToThe64)

        #expect(negatedSmallest.partialValue == .min)
        #expect(negatedSmallest.overflow)
        #expect(twoToThe127.partialValue == .min)
        #expect(twoToThe127.overflow)
        #expect(smallest.partialValue == .min)
        #expect(!smallest.overflow)
    }

    @Test("Multiplying by an Int64 reaches the smallest value without overflowing")
    func multiplyingByAnInt64() {
        let twoToThe64 = Int128Words(bitPattern: UInt128Words(high: 1, low: 0))
        let smallest = twoToThe64.multipliedReportingOverflow(byInt64: .min)
        let negatedSmallest = Int128Words.min.multipliedReportingOverflow(byInt64: -1)
        let doubledLargest = Int128Words.max.multipliedReportingOverflow(byInt64: 2)

        #expect(smallest.partialValue == .min)
        #expect(!smallest.overflow)
        #expect(negatedSmallest.partialValue == .min)
        #expect(negatedSmallest.overflow)
        #expect(doubledLargest.partialValue == -2)
        #expect(doubledLargest.overflow)
    }

    @Test("A literal factor multiplies without ambiguity")
    func literalFactor() {
        let product = Int128Words(7).multipliedReportingOverflow(by: 6)

        #expect(product.partialValue == 42)
        #expect(!product.overflow)
    }

    @Test("Multiplying at the edges of Int64 gives the full product")
    func multiplyingAtTheEdgesOfInt64() {
        let smallestSquared = Int128Words(Int64.min).multipliedReportingOverflow(by: Int128Words(Int64.min))
        let extremes = Int128Words(Int64.min).multipliedReportingOverflow(by: Int128Words(Int64.max))
        let twoToThe63 = Int128Words(bitPattern: UInt128Words(high: 0, low: 0x8000_0000_0000_0000))
        let justPastInt64 = twoToThe63.multipliedReportingOverflow(by: -1)
        let justBelowInt64 = Int128Words(-2).multipliedReportingOverflow(by: Int128Words(Int64.min) - 1)

        #expect(smallestSquared.partialValue == 85_070_591_730_234_615_865_843_651_857_942_052_864)
        #expect(!smallestSquared.overflow)
        #expect(extremes.partialValue == -85_070_591_730_234_615_856_620_279_821_087_277_056)
        #expect(!extremes.overflow)
        #expect(justPastInt64.partialValue == Int128Words(Int64.min))
        #expect(!justPastInt64.overflow)
        #expect(justBelowInt64.partialValue == 18_446_744_073_709_551_618)
        #expect(!justBelowInt64.overflow)
    }

    @Test("Halving the largest value and adding one gives two to the 126")
    func halvingTheLargest() {
        #expect(Int128Words.max / 2 + 1 == 85_070_591_730_234_615_865_843_651_857_942_052_864)
        #expect(Int128Words(-7) / 2 == -3)
    }

    @Test("Multiplying in place stores the product")
    func multiplyingInPlace() {
        var value: Int128Words = -3
        value *= 4

        #expect(value == -12)
        #expect(Int128Words(-3) * 4 == -12)
    }

    #if EXIT_TESTS_SUPPORTED
    @Test("Adding past the largest value traps")
    func addingPastTheLargestTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Int128Words.max + 1)
        }
    }

    @Test("Subtracting below the smallest value traps")
    func subtractingBelowTheSmallestTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Int128Words.min - 1)
        }
    }

    @Test("Multiplying past the range traps")
    func multiplyingPastTheRangeTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Int128Words.min * -1)
        }
    }

    @Test("Negating the smallest value traps")
    func negatingTheSmallestTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(-Int128Words.min)
        }
    }

    @Test("Dividing the smallest value by minus one traps")
    func dividingTheSmallestByMinusOneTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Int128Words.min / -1)
        }
    }

    @Test("Dividing by zero traps")
    func dividingByZeroTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Int128Words(1) / 0)
        }
    }
    #endif

    @Test("Converting to Double rounds to nearest, ties to even", arguments: doubleCases)
    private func convertsToDouble(_ testCase: DoubleCase) {
        #expect(Double(testCase.value).bitPattern == testCase.expected.bitPattern)
    }

    @Test("Parsing decimal text", arguments: parseCases)
    private func parsing(_ testCase: ParseCase) {
        #expect(Int128Words(testCase.text) == testCase.expected)
        #expect(Int128Words(Substring(testCase.text)) == testCase.expected)
    }

    #if _runtime(_ObjC)
    @Test("Parsing text whose UTF-8 isn't stored contiguously")
    func parsingNonContiguousText() {
        let characters = Array("€-170141183460469231731687303715884105728".utf16)
        let text = NSString(characters: characters, length: characters.count) as String
        let smallestText = Substring(text).dropFirst()

        // The euro sign keeps the `NSString` in UTF-16, so its UTF-8 view has no storage to lend.
        #expect(smallestText.utf8.withContiguousStorageIfAvailable { _ in true } == nil)
        #expect(Int128Words(smallestText) == .min)
        #expect(Int128Words(text) == nil)
    }
    #endif

    @Test("Multiplying by ten and adding a digit", arguments: digitCases)
    private func multiplyingByTenAdding(_ testCase: DigitCase) {
        #expect(testCase.value.multipliedByTenAdding(testCase.digit) == testCase.expected)
    }
}
