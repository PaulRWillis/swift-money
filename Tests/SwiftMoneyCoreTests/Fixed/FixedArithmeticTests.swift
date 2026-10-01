import SwiftMoneyCore
import Testing

// A stored value and a power of ten, 10^-k, to multiply it by.
private struct PowerOfTenProduct: Sendable, CustomTestStringConvertible {
    let storage: Int128
    let k: Int

    var testDescription: String {
        "\(storage) × 10^-\(k)"
    }
}

private let everyRule: [RoundingRule] = [
    .towardZero, .awayFromZero, .down, .up, .toNearestOrEven, .toNearestOrAwayFromZero,
]

private let largestStoredPowerOfTenLessOne: Int128 = 99_999_999_999_999_999_999_999_999_999_999_999_999

private let powerOfTenProducts: [PowerOfTenProduct] = samples(
    zip(
        Gen { seed in Int128.random(in: .min ... .max, using: &seed) },
        Gen<Int64>.int(in: 1 ... 18).map(Int.init)
    ).map { PowerOfTenProduct(storage: $0, k: $1) },
    seed: PropertySeed.powerOfTenProduct,
    edges: [Int128.max, Int128.min, largestStoredPowerOfTenLessOne, -largestStoredPowerOfTenLessOne, 1, -1]
        .flatMap { storage in [1, 9, 18].map { PowerOfTenProduct(storage: storage, k: $0) } }
)

@Suite("Fixed Arithmetic Tests")
struct FixedArithmeticTests {

    // The right-hand side rounds through the constructor's own division, so it checks the product's
    // remainders and ties independently.
    @Test("Multiplying by a power of ten rounds exactly as building the shifted value does", arguments: powerOfTenProducts)
    private func multiplyingByAPowerOfTen(_ testCase: PowerOfTenProduct) throws {
        let value = Fixed(storageBits: testCase.storage)
        let power = try #require(Fixed(significand: 1, exponent: -testCase.k))
        let shifted = try #require(Fixed(significand: testCase.storage, exponent: -18 - testCase.k))

        #expect(value * power == shifted)
    }

    @Test("A product that is exactly half a step rounds to even, across sign")
    func halfStepProductRoundsToEven() throws {
        let half = try #require(Fixed(decimal: "0.5"))

        #expect(Fixed(storageBits: 5) * half == Fixed(storageBits: 2))       // 2.5 steps
        #expect(Fixed(storageBits: 15) * half == Fixed(storageBits: 8))      // 7.5 steps
        #expect(Fixed(storageBits: -5) * half == Fixed(storageBits: -2))
        #expect(Fixed(storageBits: -15) * half == Fixed(storageBits: -8))

        // A tie whose full product needs the upper 128 bits.
        let wide = Fixed(storageBits: largestStoredPowerOfTenLessOne)
        #expect(wide * half == Fixed(storageBits: 50_000_000_000_000_000_000_000_000_000_000_000_000))
    }

    @Test("Multiplying at the edges of the range")
    func multiplyingAtTheEdges() throws {
        let largest = Fixed(storageBits: .max)
        let mostNegative = Fixed(storageBits: .min)
        let oneAndAHalf = try #require(Fixed(decimal: "1.5"))

        #expect(largest * Fixed(1) == largest)
        #expect(mostNegative * Fixed(1) == mostNegative)
        #expect(mostNegative.multipliedIfRepresentable(by: Fixed(-1)) == nil)
        #expect(largest.multipliedIfRepresentable(by: oneAndAHalf) == nil)   // fits 128 bits, not `Int128`
    }

    @Test("Addition and subtraction combine values")
    func additionSubtraction() throws {
        #expect(Fixed(2) + Fixed(3) == Fixed(5))
        #expect(Fixed(5) + Fixed(-3) == Fixed(2))
        #expect(Fixed(7) + Fixed(-7) == .zero)
        #expect(Fixed(5) - Fixed(3) == Fixed(2))
        #expect(Fixed(3) - Fixed(5) == Fixed(-2))

        let quarter = try #require(Fixed(decimal: "0.25"))
        let half = try #require(Fixed(decimal: "0.5"))
        let threeQuarters = try #require(Fixed(decimal: "0.75"))
        #expect(quarter + half == threeQuarters)
        #expect(threeQuarters - quarter == half)
    }

    @Test("A thousand pounds times five percent is fifty pounds")
    func moneyStyleProduct() throws {
        let thousandPounds = Fixed(100_000)               // minor units
        let fivePercent = try #require(Fixed(decimal: "0.05"))

        #expect(thousandPounds * fivePercent == Fixed(5_000))
    }

    @Test("Multiplication commutes")
    func multiplicationCommutes() throws {
        let three = Fixed(3)
        let quarter = try #require(Fixed(decimal: "0.25"))

        #expect(three * quarter == quarter * three)
        #expect(three * quarter == Fixed(decimal: "0.75"))
    }

    @Test("Dividing undoes multiplying for exact values")
    func multiplyThenDivide() throws {
        let seven = Fixed(7)
        let eighth = try #require(Fixed(decimal: "0.125"))

        #expect((seven * eighth) / eighth == seven)
    }

    @Test("Exact division gives the exact quotient")
    func exactDivision() throws {
        let sixTenths = try #require(Fixed(decimal: "0.6"))
        let twoTenths = try #require(Fixed(decimal: "0.2"))

        #expect(sixTenths / twoTenths == Fixed(3))
    }

    @Test("Non-terminating division rounds at the eighteenth digit")
    func nonTerminatingDivision() {
        // 1 / 3 = 0.333…333 to eighteen places; the true next digit is 3, so it truncates.
        #expect(Fixed(1) / Fixed(3) == Fixed(significand: 333_333_333_333_333_333, exponent: -18))
    }

    @Test("A product whose quotient fills both words rounds at the eighteenth digit")
    func twoWordQuotientRounds() throws {
        let tenth = try #require(Fixed(decimal: "0.1"))
        let wide = Fixed(storageBits: 99_999_999_999_999_999_999_999_999_999_999_999_999)

        #expect(wide * tenth == Fixed(storageBits: 10_000_000_000_000_000_000_000_000_000_000_000_000))
        #expect(Fixed(storageBits: -99_999_999_999_999_999_999_999_999_999_999_999_999) * tenth
            == Fixed(storageBits: -10_000_000_000_000_000_000_000_000_000_000_000_000))
    }

    // Found by a search over every high word the divide accepts: each is divided wrongly by a reciprocal
    // one too small, which a sample of money-sized amounts alone never finds.
    @Test("A product with a large whole part divides by the scale exactly")
    func largeWholeProductsDivideExactly() {
        #expect(Fixed(storageBits: 17_068_515_517_480_262_036_209_373_148_206_837_343) * Fixed(storageBits: 1)
            == Fixed(storageBits: 17_068_515_517_480_262_036))
        #expect(Fixed(storageBits: 15_634_048_796_563_106_562_155_515_374_148_585_873) * Fixed(storageBits: 1)
            == Fixed(storageBits: 15_634_048_796_563_106_562))
    }

    @Test("Every rule divides a whole quotient without a step", arguments: everyRule)
    func everyRuleDividesAWholeQuotientExactly(rule: RoundingRule) {
        #expect(Fixed(6).divided(by: 3, rounding: rule) == Fixed(2))
        #expect(Fixed(-6).divided(by: 3, rounding: rule) == Fixed(-2))
    }

    @Test("A large product within range does not trap")
    func largeProductInRange() {
        #expect(Fixed(1_000_000_000) * Fixed(1_000_000_000) == Fixed(1_000_000_000_000_000_000))
    }

    @Test("Scaling by an integer multiplies the value")
    func multipliedByInteger() throws {
        let half = try #require(Fixed(decimal: "0.5"))

        #expect(half.multiplied(by: 3) == Fixed(decimal: "1.5"))
        #expect(Fixed(2).multiplied(by: -4) == Fixed(-8))
    }

    @Test("Dividing by an integer splits the value")
    func dividedByInteger() {
        #expect(Fixed(10).divided(by: 5) == Fixed(2))
        #expect(Fixed(1).divided(by: 4) == Fixed(decimal: "0.25"))
        #expect(Fixed(1).divided(by: 3) == Fixed(significand: 333_333_333_333_333_333, exponent: -18))
        #expect(Fixed(2).divided(by: 3) == Fixed(significand: 666_666_666_666_666_667, exponent: -18))
    }

    // `exponent: -18` names the least significant digit, so a `significand:` there reads as the stored
    // value — the way to construct and check the extremes through the public interface.
    @Test("Integer division ties to even, symmetrically across sign", arguments: [
        (Int128(5), Fixed.Divisor(2), Int128(2)),          // 2.5 → 2 (even)
        (Int128(7), Fixed.Divisor(2), Int128(4)),          // 3.5 → 4 (even)
        (Int128(-7), Fixed.Divisor(2), Int128(-4)),
        (Int128(-5), Fixed.Divisor(2), Int128(-2)),        // -2.5 → -2 (even)
        (Int128.min, Fixed.Divisor(1), Int128.min),        // taken from its magnitude, never negated
        (Int128.max, Fixed.Divisor(2), Int128.max / 2 + 1),
    ])
    func integerDivisionRoundsHalfToEven(_ testCase: (storage: Int128, divisor: Fixed.Divisor, expected: Int128)) throws {
        let value = try #require(Fixed(significand: testCase.storage, exponent: -18))
        let expected = try #require(Fixed(significand: testCase.expected, exponent: -18))

        #expect(value.divided(by: testCase.divisor) == expected)
    }

    @Test("Integer division honours the caller's rounding rule")
    func integerDivisionRounding() throws {
        // 1/3 is non-terminating, so the rule decides the eighteenth digit.
        #expect(Fixed(1).divided(by: 3, rounding: .up) > Fixed(1).divided(by: 3, rounding: .down))
        // The default matches the rule-less divide.
        #expect(Fixed(1).divided(by: 3, rounding: .toNearestOrEven) == Fixed(1).divided(by: 3))
        // 1/4 terminates, so every rule agrees.
        let quarter = try #require(Fixed(decimal: "0.25"))
        #expect(Fixed(1).divided(by: 4, rounding: .up) == quarter)
        #expect(Fixed(1).divided(by: 4, rounding: .down) == quarter)
    }

    @Test("Directed division rounding follows the sign")
    func integerDivisionDirectedBySign() {
        // Rounding toward +∞ is never below rounding toward −∞, on either side of zero.
        #expect(Fixed(-1).divided(by: 3, rounding: .up) > Fixed(-1).divided(by: 3, rounding: .down))
        // Toward-zero versus away-from-zero on a negative value.
        #expect(Fixed(-7).divided(by: 3, rounding: .towardZero) > Fixed(-7).divided(by: 3, rounding: .awayFromZero))
    }

    @Test("Daily accrual over five years stays within a minor unit of the single-shot result")
    func dailyAccrualPrecision() throws {
        let balance = Fixed(1_000_000)                    // £10,000 = 1,000,000 minor units
        let rate = try #require(Fixed(decimal: "0.05"))   // 5%
        let days: Int128 = 1_826

        let dailyInterest = (balance * rate).divided(by: 365)
        var accrued = Fixed.zero
        for _ in 0 ..< days {
            accrued = accrued + dailyInterest
        }

        let singleShot = (balance * rate).multiplied(by: days).divided(by: 365)
        let difference = accrued - singleShot

        #expect(difference < Fixed(1))       // within one minor unit, either way
        #expect(Fixed(-1) < difference)
    }

    @Test("Division by zero traps")
    func divisionByZeroTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(1) / .zero)
        }
    }

    @Test("A product beyond the range traps")
    func productOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            let big = Fixed(1_000_000_000_000)   // 1e12; its square is out of range
            blackHole(big * big)
        }
    }

    @Test("Division that rounds up carries the eighteenth digit")
    func divisionRoundsUp() {
        // 2 / 3 = 0.666…667 — the true nineteenth digit is 6, so the eighteenth rounds up.
        #expect(Fixed(2) / Fixed(3) == Fixed(significand: 666_666_666_666_666_667, exponent: -18))
    }

    @Test("Division past the range traps")
    func divisionOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            let tiny = Fixed(decimal: "0.000000001")   // 1e-9
            blackHole(tiny.map { Fixed(1_000_000_000_000) / $0 })
        }
    }
}
