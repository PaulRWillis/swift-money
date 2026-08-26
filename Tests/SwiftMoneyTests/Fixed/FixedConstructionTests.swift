import SwiftMoney
import Testing

@Suite("Fixed Construction Tests")
struct FixedConstructionTests {

    @Test("Decimals, significand-exponent, and arithmetic agree on the same value")
    func constructionAgrees() {
        #expect(Fixed(decimal: "0.5") == Fixed(1).divided(by: 2))
        #expect(Fixed(decimal: "0.25") == Fixed(1).divided(by: 4))
        #expect(Fixed(decimal: ".5") == Fixed(1).divided(by: 2))
        #expect(Fixed(decimal: "0.175") == Fixed(significand: 175, exponent: -3))
        #expect(Fixed(decimal: "-0.05") == Fixed(significand: -5, exponent: -2))
        #expect(Fixed(decimal: "3") == Fixed(3))
        #expect(Fixed(decimal: "0.8765262907") == Fixed(significand: 8_765_262_907, exponent: -10))
    }

    @Test("A decimal reads back as the same Double")
    func decimalDoubleRoundTrip() throws {
        #expect(abs(try #require(Fixed(decimal: "0.175")).double - 0.175) < 1e-12)
        #expect(abs(try #require(Fixed(decimal: "100")).double - 100.0) < 1e-12)
    }

    // `exponent: -18` names the least significant digit, so a `significand:` there reads as the stored value.
    @Test("More than eighteen digits rounds by the caller's rule")
    func excessDigitsRound() {
        // 15 × 10^-19 = 1.5 × 10^-18, exactly half of the eighteenth-digit step.
        let evenNeighbour = Fixed(significand: 2, exponent: -18)
        let towardZero = Fixed(significand: 1, exponent: -18)

        #expect(Fixed(significand: 15, exponent: -19, rounding: .toNearestOrEven) == evenNeighbour)
        #expect(Fixed(significand: 15, exponent: -19, rounding: .toNearestOrAwayFromZero) == evenNeighbour)
        #expect(Fixed(significand: 15, exponent: -19, rounding: .awayFromZero) == evenNeighbour)
        #expect(Fixed(significand: 15, exponent: -19, rounding: .up) == evenNeighbour)
        #expect(Fixed(significand: 15, exponent: -19, rounding: .towardZero) == towardZero)
        #expect(Fixed(significand: 15, exponent: -19, rounding: .down) == towardZero)
    }

    @Test("Directed rounding follows the sign")
    func directedRoundingBySign() {
        // -1.5 × 10^-18.
        #expect(Fixed(significand: -15, exponent: -19, rounding: .up) == Fixed(significand: -1, exponent: -18))
        #expect(Fixed(significand: -15, exponent: -19, rounding: .down) == Fixed(significand: -2, exponent: -18))
        #expect(Fixed(significand: -15, exponent: -19, rounding: .toNearestOrEven) == Fixed(significand: -2, exponent: -18))
    }

    @Test("Rejects non-decimal strings")
    func rejectsMalformed() {
        #expect(Fixed(decimal: "1.2.3") == nil)
        #expect(Fixed(decimal: "1/3") == nil)
        #expect(Fixed(decimal: "1e3") == nil)
        #expect(Fixed(decimal: "") == nil)
        #expect(Fixed(decimal: "abc") == nil)
        #expect(Fixed(decimal: ".") == nil)
        #expect(Fixed(decimal: "-") == nil)
    }

    @Test("A string with more than eighteen fraction digits rounds at the eighteenth")
    func longDecimalRounds() {
        let twentyTwoThrees = "0." + String(repeating: "3", count: 22)
        #expect(Fixed(decimal: twentyTwoThrees) == Fixed(significand: 333_333_333_333_333_333, exponent: -18))

        let halfUlp = "0." + String(repeating: "0", count: 18) + "5"           // 5 × 10^-19
        #expect(Fixed(decimal: halfUlp, rounding: .toNearestOrEven) == .zero)

        let onePointFiveUlp = "0." + String(repeating: "0", count: 17) + "15"  // 1.5 × 10^-18
        #expect(Fixed(decimal: onePointFiveUlp, rounding: .toNearestOrEven) == Fixed(significand: 2, exponent: -18))
    }

    @Test("Values out of range fail or trap")
    func outOfRange() async {
        #expect(Fixed(exactly: Int128.max) == nil)                          // × scale overflows
        #expect(Fixed(significand: 1, exponent: 21) == nil)                 // 10^39 overflows
        #expect(Fixed(decimal: String(repeating: "9", count: 40)) == nil)   // significand too large

        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(Int128.max))
        }
    }

    @Test("Approximates a Double as its shortest decimal")
    func approximatesDouble() {
        #expect(Fixed(approximating: 0.05) == Fixed(decimal: "0.05"))
        #expect(Fixed(approximating: 0.175) == Fixed(decimal: "0.175"))
        #expect(Fixed(approximating: 3.0) == Fixed(3))

        #expect(Fixed(approximating: .nan) == nil)
        #expect(Fixed(approximating: .infinity) == nil)
        #expect(Fixed(approximating: 1e30) == nil)
    }

    @Test("Approximating then reading back round-trips")
    func approximateRoundTrip() throws {
        let fixed = try #require(Fixed(approximating: 0.175))

        #expect(abs(fixed.double - 0.175) < 1e-12)
    }
}
