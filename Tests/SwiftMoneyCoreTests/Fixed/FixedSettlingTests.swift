import SwiftMoneyCore
import Testing

@Suite("Fixed Settling Tests")
struct FixedSettlingTests {

    @Test("The largest Int64 settles, and a fraction above it settles only toward it")
    func largestInt64Edge() throws {
        let aboveLargest = try #require(Fixed(decimal: "9223372036854775807.4"))

        #expect(Int64(Fixed(Int64.max), rounding: .up) == 9_223_372_036_854_775_807)
        #expect(Int64(aboveLargest, rounding: .toNearestOrEven) == 9_223_372_036_854_775_807)
        #expect(Int64(aboveLargest, rounding: .up) == nil)
    }

    @Test("The smallest Int64 settles, and a fraction below it settles only toward it")
    func smallestInt64Edge() throws {
        let belowSmallest = try #require(Fixed(decimal: "-9223372036854775808.4"))

        #expect(Int64(Fixed(Int64.min), rounding: .down) == -9_223_372_036_854_775_808)
        #expect(Int64(belowSmallest, rounding: .up) == -9_223_372_036_854_775_808)
        #expect(Int64(belowSmallest, rounding: .down) == nil)
    }

    // Int64.max is odd, so half-to-even steps a tie past it.
    @Test("A tie just above the largest Int64 settles only toward it")
    func tieAboveLargest() throws {
        let tie = try #require(Fixed(decimal: "9223372036854775807.5"))

        #expect(Int64(tie, rounding: .toNearestOrEven) == nil)
        #expect(Int64(tie, rounding: .towardZero) == 9_223_372_036_854_775_807)
    }

    // Int64.min is even, so half-to-even keeps a tie on it.
    @Test("A tie just below the smallest Int64 settles to it under half-to-even")
    func tieBelowSmallest() throws {
        let tie = try #require(Fixed(decimal: "-9223372036854775808.5"))

        #expect(Int64(tie, rounding: .toNearestOrEven) == -9_223_372_036_854_775_808)
        #expect(Int64(tie, rounding: .toNearestOrAwayFromZero) == nil)
    }

    @Test("A value whose whole part needs more than a word does not settle")
    func twoWordWholesDoNotSettle() throws {
        let justPastOneWord = try #require(Fixed(exactly: Int128Words(bitPattern: UInt128Words(high: 1, low: 0))))

        #expect(Int64(justPastOneWord, rounding: .towardZero) == nil)
        #expect(Int64(Fixed(storageBits: .max), rounding: .towardZero) == nil)
        #expect(Int64(Fixed(storageBits: .min), rounding: .towardZero) == nil)
        #expect(Int64(exactly: Fixed(storageBits: .min)) == nil)
    }

    // High word 10^18 − 1 and low word all ones: the largest magnitude the one-step divide accepts. Its
    // whole part is 18_446_744_073_709_551_615, past Int64.max.
    @Test("The largest one-step dividend divides, and its whole part is past Int64")
    func largestOneStepDividend() {
        let largestOneStep = Int128Words(bitPattern: UInt128Words(high: 999_999_999_999_999_999, low: .max))

        #expect(Int64(Fixed(storageBits: largestOneStep), rounding: .towardZero) == nil)
    }

    // Whole part UInt64.max and one part over: stepping away from zero would wrap to zero.
    @Test("A step past the largest one-word whole part does not settle")
    func stepPastTheLargestWholePart() {
        let largestWholeAndAPart = Fixed(storageBits: 18_446_744_073_709_551_615_000_000_000_000_000_001)

        #expect(Int64(largestWholeAndAPart, rounding: .awayFromZero) == nil)
    }

    @Test("A fraction just under a whole unit settles by the rule")
    func justUnderAUnit() {
        #expect(Int64(Fixed(storageBits: 999_999_999_999_999_999), rounding: .towardZero) == 0)
        #expect(Int64(Fixed(storageBits: 999_999_999_999_999_999), rounding: .awayFromZero) == 1)
    }

    @Test("A whole unit, and just past it, settle to one")
    func atAndJustPastAUnit() {
        #expect(Int64(Fixed(storageBits: 1_000_000_000_000_000_000), rounding: .awayFromZero) == 1)
        #expect(Int64(Fixed(storageBits: 1_000_000_000_000_000_001), rounding: .towardZero) == 1)
    }

    @Test("Half a unit, and one part either side, settle to the nearest")
    func aroundHalfAUnit() {
        #expect(Int64(Fixed(storageBits: 500_000_000_000_000_000), rounding: .toNearestOrEven) == 0)
        #expect(Int64(Fixed(storageBits: 1_500_000_000_000_000_000), rounding: .toNearestOrEven) == 2)
        #expect(Int64(Fixed(storageBits: 500_000_000_000_000_001), rounding: .toNearestOrEven) == 1)
        #expect(Int64(Fixed(storageBits: 499_999_999_999_999_999), rounding: .toNearestOrAwayFromZero) == 0)
    }

    // Each is the first dividend a reciprocal one or two too large got wrong.
    @Test("Settling divides amounts a slightly large reciprocal would get wrong")
    func reciprocalSensitiveAmounts() {
        let positive = Fixed(storageBits: 8_562_404_084_215_871_889_138_389_474_567_859_493)
        let negative = Fixed(storageBits: -8_562_404_084_215_871_889_138_389_474_567_859_493)
        let second = Fixed(storageBits: 6_278_178_795_411_266_307_584_138_874_821_461_178)
        let third = Fixed(storageBits: 8_573_934_747_461_687_591_167_645_805_909_555_981)

        #expect(Int64(positive, rounding: .towardZero) == 8_562_404_084_215_871_889)
        #expect(Int64(negative, rounding: .awayFromZero) == -8_562_404_084_215_871_890)
        #expect(Int64(second, rounding: .towardZero) == 6_278_178_795_411_266_307)
        #expect(Int64(third, rounding: .toNearestOrEven) == 8_573_934_747_461_687_591)
    }
}
