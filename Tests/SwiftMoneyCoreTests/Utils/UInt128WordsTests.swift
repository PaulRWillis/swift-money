import SwiftMoneyCore
import Testing

// A 256-bit dividend, a divisor and the quotient and remainder they give, written out as words.
private struct WideQuotient: Sendable, CustomTestStringConvertible {
    let name: String
    let dividendHigh: UInt128Words
    let dividendLow: UInt128Words
    let divisor: UInt128Words
    let quotient: UInt128Words
    let remainder: UInt128Words

    var testDescription: String {
        name
    }
}

// The vectors that drive each branch of the long division's quotient estimate. With a divisor whose top
// bit is set, the dividend's top word equal to the divisor's makes the first estimate the largest word.
private let wideQuotients: [WideQuotient] = [
    WideQuotient(
        name: "estimate is the largest word, then one too large",
        dividendHigh: UInt128Words(high: 0x8000_0000_0000_0000, low: 0x1234_5678_9ABC_DEF0),
        dividendLow: UInt128Words(high: 0xFEDC_BA98_7654_3210, low: 0x0F0F_0F0F_0F0F_0F0F),
        divisor: UInt128Words(high: 0x8000_0000_0000_0000, low: 0xFFFF_FFFF_FFFF_FFFF),
        quotient: UInt128Words(high: 0xFFFF_FFFF_FFFF_FFFE, low: 0x2468_ACF1_3579_BDE7),
        remainder: UInt128Words(high: 0x5A74_0DA7_40DA_7427, low: 0x3377_BC00_4488_CCF6)
    ),
    WideQuotient(
        name: "estimate is the largest word, its remainder past one word",
        dividendHigh: UInt128Words(high: 0xFFFF_FFFF_FFFF_FFFF, low: 0xFFFF_FFFF_FFFF_FFFE),
        dividendLow: UInt128Words(high: 0, low: 0),
        divisor: UInt128Words(high: 0xFFFF_FFFF_FFFF_FFFF, low: 0xFFFF_FFFF_FFFF_FFFF),
        quotient: UInt128Words(high: 0xFFFF_FFFF_FFFF_FFFF, low: 0xFFFF_FFFF_FFFF_FFFE),
        remainder: UInt128Words(high: 0xFFFF_FFFF_FFFF_FFFF, low: 0xFFFF_FFFF_FFFF_FFFE)
    ),
    WideQuotient(
        name: "estimate is the largest word, then corrected once",
        dividendHigh: UInt128Words(high: 0x8000_0000_0000_0352, low: 0x5052_1ED9_D6A9_3EB2),
        dividendLow: UInt128Words(high: 0xCB43_261C_284B_E594, low: 0),
        divisor: UInt128Words(high: 0x8000_0000_0000_0352, low: 0xFFFF_FFFF_FFFF_FE91),
        quotient: UInt128Words(high: 0xFFFF_FFFF_FFFF_FFFE, low: 0xA0A4_3DB3_AD52_8963),
        remainder: UInt128Words(high: 0x494A_09D2_FEED_2F83, low: 0x4B74_7495_7952_F4ED)
    ),
    WideQuotient(
        name: "estimate is two too large",
        dividendHigh: UInt128Words(high: 0x4291_DD72_D8E3_E3EB, low: 0xD458_21CC_65A2_FFFC),
        dividendLow: UInt128Words(high: 0x6010_9250_5662_2F43, low: 0),
        divisor: UInt128Words(high: 0x8000_0000_0000_051F, low: 0xFFFF_FFFF_FFFF_C69E),
        quotient: UInt128Words(high: 0x8523_BAE5_B1C7_C282, low: 0xFA74_913A_8BBC_7D21),
        remainder: UInt128Words(high: 0x36F2_F6C7_B928_860A, low: 0xD4F5_A186_7604_3FA2)
    ),
    WideQuotient(
        name: "a one-word divisor",
        dividendHigh: UInt128Words(high: 0, low: 0x0DE0_B6B3_A763_FFFF),
        dividendLow: UInt128Words(high: 0xFFFF_FFFF_FFFF_FFFF, low: 0xFFFF_FFFF_FFFF_FFFF),
        divisor: UInt128Words(high: 0, low: 0x0DE0_B6B3_A764_0000),
        quotient: UInt128Words(high: 0xFFFF_FFFF_FFFF_FFFF, low: 0xFFFF_FFFF_FFFF_FFFF),
        remainder: UInt128Words(high: 0, low: 0x0DE0_B6B3_A763_FFFF)
    ),
    WideQuotient(
        name: "a divisor with the top bit clear",
        dividendHigh: UInt128Words(high: 0, low: 0),
        dividendLow: UInt128Words(high: 0, low: 7),
        divisor: UInt128Words(high: 1, low: 0),
        quotient: UInt128Words(high: 0, low: 0),
        remainder: UInt128Words(high: 0, low: 7)
    ),
]

// A dividend, a one-word divisor and the quotient and remainder they give, at the edges between a
// dividend that fits one word and one that doesn't, and between divisors below and above 2^32.
private struct WordQuotient: Sendable, CustomTestStringConvertible {
    let name: String
    let dividend: UInt128Words
    let divisor: UInt64
    let quotient: UInt128Words
    let remainder: UInt64

    var testDescription: String {
        name
    }
}

private let wordQuotients: [WordQuotient] = [
    WordQuotient(
        name: "a one-word dividend",
        dividend: UInt128Words(high: 0, low: 0x0000_0000_3B9A_CA07),
        divisor: 0xFFFF_FFFF,
        quotient: 0,
        remainder: 0x3B9A_CA07
    ),
    WordQuotient(
        name: "a dividend just past one word, by three",
        dividend: UInt128Words(high: 1, low: 1),
        divisor: 3,
        quotient: UInt128Words(high: 0, low: 0x5555_5555_5555_5555),
        remainder: 2
    ),
    WordQuotient(
        name: "a dividend just past one word, by 2^32 - 1",
        dividend: UInt128Words(high: 1, low: 0),
        divisor: 0xFFFF_FFFF,
        quotient: UInt128Words(high: 0, low: 0x0000_0001_0000_0001),
        remainder: 1
    ),
    WordQuotient(
        name: "the largest dividend, by 2^32 - 1",
        dividend: .max,
        divisor: 0xFFFF_FFFF,
        quotient: UInt128Words(high: 0x0000_0001_0000_0001, low: 0x0000_0001_0000_0001),
        remainder: 0
    ),
    WordQuotient(
        name: "the largest dividend, by 2^32",
        dividend: .max,
        divisor: 0x1_0000_0000,
        quotient: UInt128Words(high: 0x0000_0000_FFFF_FFFF, low: 0xFFFF_FFFF_FFFF_FFFF),
        remainder: 0xFFFF_FFFF
    ),
    WordQuotient(
        name: "the largest dividend, by 2^64 - 1",
        dividend: .max,
        divisor: 0xFFFF_FFFF_FFFF_FFFF,
        quotient: UInt128Words(high: 1, low: 1),
        remainder: 0
    ),
]

@Suite("UInt128Words Tests")
struct UInt128WordsTests {

    @Test("A literal fills both words")
    func literalFillsBothWords() {
        let zero: UInt128Words = 0
        let wordMax: UInt128Words = 18_446_744_073_709_551_615
        let pastOneWord: UInt128Words = 18_446_744_073_709_551_616
        let largest: UInt128Words = 340_282_366_920_938_463_463_374_607_431_768_211_455

        #expect(zero == UInt128Words(high: 0, low: 0))
        #expect(wordMax == UInt128Words(high: 0, low: .max))
        #expect(pastOneWord == UInt128Words(high: 1, low: 0))
        #expect(largest == UInt128Words(high: .max, low: .max))
    }

    @Test("The largest and smallest values")
    func largestAndSmallest() {
        #expect(UInt128Words.max == UInt128Words(high: .max, low: .max))
        #expect(UInt128Words.min == UInt128Words(high: 0, low: 0))
    }

    @Test("A UInt64 becomes the low word")
    func wordBecomesTheLowWord() {
        #expect(UInt128Words(UInt64.max) == UInt128Words(high: 0, low: .max))
    }

    @Test("The high word decides order before the low word")
    func highWordDecidesOrder() {
        #expect(UInt128Words(high: 0, low: .max) < UInt128Words(high: 1, low: 0))
        #expect(!(UInt128Words(high: 1, low: 0) < UInt128Words(high: 0, low: .max)))
        #expect(UInt128Words(high: 1, low: 0) < UInt128Words(high: 1, low: 1))
    }

    @Test("Adding carries into the high word and overflows past the largest value")
    func addingCarries() {
        let carried = UInt128Words(high: 0, low: .max).addingReportingOverflow(1)
        let wrapped = UInt128Words.max.addingReportingOverflow(1)

        #expect(carried.partialValue == UInt128Words(high: 1, low: 0))
        #expect(!carried.overflow)
        #expect(wrapped.partialValue == 0)
        #expect(wrapped.overflow)
    }

    @Test("Subtracting borrows from the high word and overflows below zero")
    func subtractingBorrows() {
        let borrowed = UInt128Words(high: 1, low: 0).subtractingReportingOverflow(1)
        let wrapped = UInt128Words.min.subtractingReportingOverflow(1)

        #expect(borrowed.partialValue == UInt128Words(high: 0, low: .max))
        #expect(!borrowed.overflow)
        #expect(wrapped.partialValue == .max)
        #expect(wrapped.overflow)
        #expect(UInt128Words(high: 1, low: 0) - 1 == UInt128Words(high: 0, low: .max))
    }

    #if EXIT_TESTS_SUPPORTED
    @Test("Subtracting below zero traps")
    func subtractingBelowZeroTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(UInt128Words.min - 1)
        }
    }
    #endif

    @Test("Multiplying overflows once the product needs a third word")
    func multiplyingOverflows() {
        let wordMax = UInt128Words(high: 0, low: .max)
        let largestSquare = wordMax.multipliedReportingOverflow(by: wordMax)
        let bothHighWords = UInt128Words(high: 1, low: 0).multipliedReportingOverflow(by: UInt128Words(high: 1, low: 0))
        let crossProduct = UInt128Words(high: 2, low: 0).multipliedReportingOverflow(by: UInt128Words(high: 0, low: 1 << 63))
        let carryOut = UInt128Words(high: 0, low: .max).multipliedReportingOverflow(by: UInt128Words(high: 1, low: .max))
        let byOne = UInt128Words.max.multipliedReportingOverflow(by: 1)

        #expect(largestSquare.partialValue == UInt128Words(high: 0xFFFF_FFFF_FFFF_FFFE, low: 1))
        #expect(!largestSquare.overflow)
        #expect(bothHighWords.partialValue == 0)
        #expect(bothHighWords.overflow)
        #expect(crossProduct.partialValue == 0)
        #expect(crossProduct.overflow)
        #expect(carryOut.overflow)
        #expect(byOne.partialValue == .max)
        #expect(!byOne.overflow)
    }

    @Test("The full-width square of the largest value")
    func fullWidthSquareOfTheLargest() {
        let product = UInt128Words.max.multipliedFullWidth(by: .max)

        #expect(product.high == UInt128Words(high: .max, low: 0xFFFF_FFFF_FFFF_FFFE))
        #expect(product.low == 1)
    }

    @Test("Dividing a 256-bit value", arguments: wideQuotients)
    private func dividingFullWidth(_ vector: WideQuotient) {
        let result = vector.divisor.dividingFullWidth((high: vector.dividendHigh, low: vector.dividendLow))

        #expect(result.quotient == vector.quotient)
        #expect(result.remainder == vector.remainder)
    }

    #if EXIT_TESTS_SUPPORTED
    @Test("Dividing a 256-bit value whose quotient needs a third word traps")
    func dividingFullWidthPastTheRangeTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(UInt128Words(high: 0, low: 7).dividingFullWidth((high: UInt128Words(high: 0, low: 7), low: 0)))
        }
    }
    #endif

    @Test("Dividing by a divisor whose estimate is one too large")
    func dividingWithAnEstimateOneTooLarge() {
        let dividend = UInt128Words(high: 0xA237_17B9_3AB0_A434, low: 0x3BB2_6A46_F695_F332)
        let divisor = UInt128Words(high: 0x0000_0000_0000_00D3, low: 0xFFFF_FF07_AC4B_E3A7)

        let result = dividend.quotientAndRemainder(dividingBy: divisor)

        #expect(result.quotient == UInt128Words(high: 0, low: 0x00C3_E1EC_5952_F5CC))
        #expect(result.remainder == UInt128Words(high: 0x0000_0000_0000_004A, low: 0xF004_A0DD_0EBF_B71E))
    }

    @Test("Dividing by a one-word divisor uses both words of the dividend")
    func dividingByAWord() {
        let result = UInt128Words.max.quotientAndRemainder(dividingBy: 10)

        #expect(result.quotient == UInt128Words(high: 0x1999_9999_9999_9999, low: 0x9999_9999_9999_9999))
        #expect(result.remainder == 5)
    }

    @Test("Dividing by a one-word divisor", arguments: wordQuotients)
    private func dividingByOneWord(_ vector: WordQuotient) {
        let result = vector.dividend.quotientAndRemainder(dividingBy: UInt128Words(vector.divisor))

        #expect(result.quotient == vector.quotient)
        #expect(result.remainder == UInt128Words(vector.remainder))
    }

    @Test("Dividing a 256-bit value by a one-word divisor", arguments: wordQuotients)
    private func dividingFullWidthByOneWord(_ vector: WordQuotient) {
        let result = UInt128Words(vector.divisor).dividingFullWidth((high: 0, low: vector.dividend))

        #expect(result.quotient == vector.quotient)
        #expect(result.remainder == UInt128Words(vector.remainder))
    }

    @Test("Dividing a 256-bit value whose upper half is just below a half-word divisor")
    func dividingFullWidthJustBelowAHalfWordDivisor() {
        let divisor = UInt128Words(0xFFFF_FFFF)
        let result = divisor.dividingFullWidth((high: UInt128Words(0xFFFF_FFFE), low: .max))

        #expect(result.quotient == .max)
        #expect(result.remainder == UInt128Words(0xFFFF_FFFE))
    }

    @Test("Dividing by a larger divisor gives zero and the dividend back")
    func dividingByALargerDivisor() {
        let result = UInt128Words(high: 1, low: 0).quotientAndRemainder(dividingBy: UInt128Words(high: 1, low: 1))

        #expect(result.quotient == 0)
        #expect(result.remainder == UInt128Words(high: 1, low: 0))
    }

    @Test("Dividing the largest value by itself")
    func dividingTheLargestByItself() {
        let result = UInt128Words.max.quotientAndRemainder(dividingBy: .max)

        #expect(result.quotient == 1)
        #expect(result.remainder == 0)
    }

    #if EXIT_TESTS_SUPPORTED
    @Test("Dividing by zero traps")
    func dividingByZeroTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(UInt128Words.max.quotientAndRemainder(dividingBy: 0))
        }
    }
    #endif

    @Test("Shifting moves bits across the word boundary")
    func shiftingAcrossTheWordBoundary() {
        let one: UInt128Words = 1

        #expect(one << 0 == 1)
        #expect(one << 63 == UInt128Words(high: 0, low: 0x8000_0000_0000_0000))
        #expect(one << 64 == UInt128Words(high: 1, low: 0))
        #expect(one << 127 == UInt128Words(high: 0x8000_0000_0000_0000, low: 0))
        #expect(one << 128 == 0)
        #expect(UInt128Words(high: 1, low: 0) >> 1 == UInt128Words(high: 0, low: 0x8000_0000_0000_0000))
        #expect(UInt128Words(high: 1, low: 0) >> 64 == 1)
        #expect(UInt128Words.max >> 128 == 0)
    }

    @Test("A negative shift shifts the other way")
    func negativeShiftReverses() {
        #expect(UInt128Words(high: 1, low: 0) << -64 == 1)
        #expect(UInt128Words(1) >> -64 == UInt128Words(high: 1, low: 0))
        #expect(UInt128Words.max << Int.min == 0)
        #expect(UInt128Words.max >> Int.min == 0)
    }

    @Test("Or-ing combines the words")
    func orCombinesTheWords() {
        #expect(UInt128Words(high: 1, low: 0) | UInt128Words(high: 0, low: 2) == UInt128Words(high: 1, low: 2))
    }

    @Test("Parity follows the lowest bit only")
    func parityFollowsTheLowestBit() {
        #expect(UInt128Words(high: 1, low: 2).parity == .even)
        #expect(UInt128Words(high: 0, low: 3).parity == .odd)
        #expect(Parity(of: UInt128Words(high: 2, low: 1)) == .odd)
    }
}
