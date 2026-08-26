import SwiftMoney
import Testing

@Suite("Fixed Arithmetic Tests")
struct FixedArithmeticTests {

    @Test("Addition sums the raw values")
    func additionSums() {
        #expect(Fixed(raw: 2) + Fixed(raw: 3) == Fixed(raw: 5))
        #expect(Fixed(raw: 5) + Fixed(raw: -3) == Fixed(raw: 2))
        #expect(Fixed(raw: -2) + Fixed(raw: -3) == Fixed(raw: -5))
        #expect(Fixed(raw: 7) + Fixed(raw: -7) == .zero)
    }

    @Test("Subtraction takes the difference of the raw values")
    func subtractionDiffers() {
        #expect(Fixed(raw: 5) - Fixed(raw: 3) == Fixed(raw: 2))
        #expect(Fixed(raw: 3) - Fixed(raw: 5) == Fixed(raw: -2))
        #expect(Fixed(raw: -3) - Fixed(raw: -3) == .zero)
    }

    @Test("Addition past the maximum traps")
    func additionOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(raw: .max) + Fixed(raw: 1))
        }
    }

    @Test("Subtraction past the minimum traps")
    func subtractionOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(raw: .min) - Fixed(raw: 1))
        }
    }

    @Test("A thousand pounds times five percent is fifty pounds")
    func moneyStyleProduct() {
        let thousandPounds = Fixed(raw: 100_000 * Fixed.scale)   // 100,000 minor units
        let fivePercent = Fixed(raw: Fixed.scale / 20)           // 0.05
        let fiftyPounds = Fixed(raw: 5_000 * Fixed.scale)        // 5,000 minor units

        #expect(thousandPounds * fivePercent == fiftyPounds)
    }

    @Test("Multiplication commutes")
    func multiplicationCommutes() {
        let a = Fixed(raw: 3 * Fixed.scale)     // 3.0
        let b = Fixed(raw: Fixed.scale / 4)     // 0.25

        #expect(a * b == b * a)
        #expect(a * b == Fixed(raw: 3 * Fixed.scale / 4))   // 0.75
    }

    @Test("Dividing undoes multiplying for exact values")
    func multiplyThenDivide() {
        let a = Fixed(raw: 7 * Fixed.scale)     // 7.0
        let b = Fixed(raw: Fixed.scale / 8)     // 0.125

        #expect((a * b) / b == a)
    }

    @Test("Exact division gives the exact quotient")
    func exactDivision() {
        let a = Fixed(raw: 6 * Fixed.scale / 10)   // 0.6
        let b = Fixed(raw: 2 * Fixed.scale / 10)   // 0.2

        #expect(a / b == Fixed(raw: 3 * Fixed.scale))   // 3.0
    }

    @Test("Non-terminating division rounds at the eighteenth digit")
    func nonTerminatingDivision() {
        let one = Fixed(raw: Fixed.scale)          // 1.0
        let three = Fixed(raw: 3 * Fixed.scale)    // 3.0

        // 1 / 3 = 0.333…333 to eighteen places; the true next digit is 3, so it truncates.
        #expect(one / three == Fixed(raw: 333_333_333_333_333_333))
    }

    @Test("A large product within range does not trap")
    func largeProductInRange() {
        let billion = Fixed(raw: 1_000_000_000 * Fixed.scale)   // 1e9

        #expect(billion * billion == Fixed(raw: 1_000_000_000_000_000_000 * Fixed.scale))   // 1e18
    }

    @Test("Division by zero traps")
    func divisionByZeroTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(raw: Fixed.scale) / .zero)
        }
    }

    @Test("A product beyond the range traps")
    func productOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(raw: .max) * Fixed(raw: .max))
        }
    }

    @Test("Scaling by an integer multiplies the value")
    func multipliedByInteger() {
        let half = Fixed(raw: Fixed.scale / 2)   // 0.5

        #expect(half.multiplied(by: 3) == Fixed(raw: 3 * Fixed.scale / 2))   // 1.5
        #expect(Fixed(raw: 2 * Fixed.scale).multiplied(by: -4) == Fixed(raw: -8 * Fixed.scale))
    }

    @Test("Scaling by an integer past the range traps")
    func multipliedByIntegerOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(raw: .max).multiplied(by: 2))
        }
    }

    @Test("Dividing by an integer splits the value")
    func dividedByInteger() {
        #expect(Fixed(raw: 10 * Fixed.scale).divided(by: 5) == Fixed(raw: 2 * Fixed.scale))
        #expect(Fixed(raw: Fixed.scale).divided(by: 4) == Fixed(raw: Fixed.scale / 4))   // 0.25
    }

    @Test("Dividing by three rounds at the eighteenth digit")
    func dividedByThree() {
        #expect(Fixed(raw: Fixed.scale).divided(by: 3) == Fixed(raw: 333_333_333_333_333_333))
        #expect(Fixed(raw: 2 * Fixed.scale).divided(by: 3) == Fixed(raw: 666_666_666_666_666_667))
    }

    @Test("Integer division ties to even")
    func dividedTiesToEven() {
        #expect(Fixed(raw: 5).divided(by: 2) == Fixed(raw: 2))   // 2.5 → 2
        #expect(Fixed(raw: 7).divided(by: 2) == Fixed(raw: 4))   // 3.5 → 4
    }

    @Test("Integer division is symmetric across sign")
    func dividedNegativeSymmetric() {
        #expect(Fixed(raw: -7).divided(by: 2) == Fixed(raw: -4))
        #expect(Fixed(raw: 7).divided(by: -2) == Fixed(raw: -4))
        #expect(Fixed(raw: -7).divided(by: -2) == Fixed(raw: 4))
    }

    @Test("Integer division by zero traps")
    func dividedByZeroTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(raw: Fixed.scale).divided(by: 0))
        }
    }

    @Test("Daily accrual over five years stays within a minor unit of the single-shot result")
    func dailyAccrualPrecision() {
        // Balance in minor units, so "one minor unit" is a Fixed value of 1.
        let balance = Fixed(raw: 1_000_000 * Fixed.scale)   // £10,000 = 1,000,000 minor units
        let rate = Fixed(raw: Fixed.scale / 20)             // 5%
        let days = 1_826                                    // five years

        let dailyInterest = (balance * rate).divided(by: 365)
        var accrued = Fixed.zero
        for _ in 0 ..< days {
            accrued = accrued + dailyInterest
        }

        let singleShot = (balance * rate).multiplied(by: days).divided(by: 365)

        #expect((accrued - singleShot).raw.magnitude < Fixed.scale.magnitude)
    }
}
