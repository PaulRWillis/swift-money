import SwiftMoney
import Testing

@Suite("Fixed Construction Tests")
struct FixedConstructionTests {

    @Test("A significand and exponent scale into the raw value")
    func significandExponentExact() {
        #expect(Fixed(significand: 5, exponent: -4) == Fixed(raw: 5 * Fixed.scale / 10_000))    // 0.0005
        #expect(Fixed(significand: 175, exponent: -3) == Fixed(raw: 175 * Fixed.scale / 1_000)) // 0.175
        #expect(Fixed(significand: 42, exponent: 0) == Fixed(raw: 42 * Fixed.scale))
    }

    @Test("A whole value scales by the fixed-point scale")
    func wholeValue() {
        #expect(Fixed(7) == Fixed(raw: 7 * Fixed.scale))
        #expect(Fixed(exactly: 7) == Fixed(raw: 7 * Fixed.scale))
        #expect(Fixed(-3) == Fixed(raw: -3 * Fixed.scale))
    }

    @Test("More than eighteen digits rounds by the caller's rule")
    func excessDigitsRound() {
        // 15 × 10^-19 = 1.5 × 10^-18, exactly half of the eighteenth-digit step.
        #expect(Fixed(significand: 15, exponent: -19, rounding: .toNearestOrEven) == Fixed(raw: 2))
        #expect(Fixed(significand: 15, exponent: -19, rounding: .toNearestOrAwayFromZero) == Fixed(raw: 2))
        #expect(Fixed(significand: 15, exponent: -19, rounding: .awayFromZero) == Fixed(raw: 2))
        #expect(Fixed(significand: 15, exponent: -19, rounding: .up) == Fixed(raw: 2))
        #expect(Fixed(significand: 15, exponent: -19, rounding: .towardZero) == Fixed(raw: 1))
        #expect(Fixed(significand: 15, exponent: -19, rounding: .down) == Fixed(raw: 1))
    }

    @Test("Directed rounding follows the sign")
    func directedRoundingBySign() {
        // -1.5 × 10^-18.
        #expect(Fixed(significand: -15, exponent: -19, rounding: .up) == Fixed(raw: -1))    // toward +infinity
        #expect(Fixed(significand: -15, exponent: -19, rounding: .down) == Fixed(raw: -2))  // toward -infinity
        #expect(Fixed(significand: -15, exponent: -19, rounding: .toNearestOrEven) == Fixed(raw: -2))
    }

    @Test("A value too large to scale returns nil")
    func exactlyOverflowIsNil() {
        #expect(Fixed(exactly: Int128.max) == nil)
    }

    @Test("A value too large to scale traps")
    func initOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(Int128.max))
        }
    }
}
