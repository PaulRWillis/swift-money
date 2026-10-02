import SwiftMoneyCore
import Testing

@Suite("Fixed divisor")
struct FixedDivisorTests {
    @Test("Zero is not a divisor")
    func zeroIsNotADivisor() {
        #expect(Fixed.Divisor(exactly: 0) == nil)
    }

    @Test("A negative number is not a divisor")
    func negativeIsNotADivisor() {
        #expect(Fixed.Divisor(exactly: -1) == nil)
    }

    @Test("One is a divisor")
    func oneIsADivisor() {
        #expect(Fixed.Divisor(exactly: 1) == Fixed.Divisor(1))
    }

    @Test("The largest Int128 is a divisor")
    func largestIsADivisor() {
        #expect(Fixed.Divisor(exactly: .max) == Fixed.Divisor(170_141_183_460_469_231_731_687_303_715_884_105_727))
    }

    @Test("A part count is a divisor of the same size")
    func partCountIsADivisor() {
        #expect(Fixed.Divisor(PartCount(365)) == Fixed.Divisor(365))
    }

    @Test("A unit scale is a divisor of the same size")
    func unitScaleIsADivisor() {
        #expect(Fixed.Divisor(UnitScale(100)) == Fixed.Divisor(100))
    }

    @Test("A zero divisor literal traps")
    func zeroLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let zero: Fixed.Divisor = 0
            blackHole(zero)
        }
    }

    @Test("The most negative value divided by one is itself")
    func mostNegativeByOne() throws {
        let mostNegative = try #require(Fixed(significand: .min, exponent: -18))

        #expect(mostNegative.divided(by: 1) == mostNegative)
    }
}
