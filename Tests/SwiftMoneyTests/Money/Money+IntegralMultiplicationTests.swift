import SwiftMoney
import Testing

@Suite("Money - Integral Multiplication")
struct Money_IntegralMultiplicationTests {

    // MARK: - Integral multiplication (Positive)

    @Test
    func multiplyPositiveMoneyByPositiveInt() {
        let positiveMoney = Money<TST_100>(minorUnits: 2)
        let positiveInt: Int64 = 3
        let expected = Money<TST_100>(minorUnits: 6)

        let actual = positiveMoney * positiveInt

        #expect(actual == expected)
    }

    @Test
    func multiplyPositiveMoneyByNegativeInt() {
        let positiveMoney = Money<TST_100>(minorUnits: 2)
        let negativeInt: Int64 = -3
        let expected = Money<TST_100>(minorUnits: -6)

        let actual = positiveMoney * negativeInt

        #expect(actual == expected)
    }

    @Test
    func multiplyPositiveMoneyByZeroInt() {
        let zeroMoney = Money<TST_100>(minorUnits: 0)
        let positiveInt: Int64 = 5

        let actual =  positiveInt * zeroMoney

        #expect(actual == zeroMoney)
    }

    // MARK: - Integral multiplication (negative)

    @Test
    func multiplyNegativeMoneyByPositiveInt() {
        let negativeMoney = Money<TST_100>(minorUnits: -2)
        let positiveInt: Int64 = 3
        let expected = Money<TST_100>(minorUnits: -6)

        let actual = negativeMoney * positiveInt

        #expect(actual == expected)
    }

    @Test
    func multiplyNegativeMoneyByNegativeInt() {
        let negativeMoney = Money<TST_100>(minorUnits: -3)
        let negativeInt: Int64 = -4
        let expected = Money<TST_100>(minorUnits: 12)

        let actual = negativeMoney * negativeInt

        #expect(actual == expected)
    }

    @Test
    func multiplyNegativeIntByZeroMoney() {
        let zeroMoney = Money<TST_100>(minorUnits: 0)
        let negativeInt: Int64 = -5

        let actual =  negativeInt * zeroMoney

        #expect(actual == zeroMoney)
    }

    // MARK: - Integral multiplication (zero)

    @Test
    func multiplyZeroMoneyByPositiveInt() {
        let zeroMoney = Money<TST_100>(minorUnits: 0)
        let positiveInt: Int64 = 5

        let actual = zeroMoney * positiveInt

        #expect(actual == zeroMoney)
    }

    @Test
    func multiplyZeroMoneyByNegativeInt() {
        let zeroMoney = Money<TST_100>(minorUnits: 0)
        let negativeInt: Int64 = -2

        let actual = zeroMoney * negativeInt

        #expect(actual == zeroMoney)
    }

    @Test
    func multiplyZeroMoneyByZeroInt() {
        let zeroMoney = Money<TST_100>(minorUnits: 0)
        let zeroInt = Int64.zero

        let actual = zeroMoney * zeroInt

        #expect(actual == zeroMoney)
    }

    // MARK: - NaN traps

    @Test("Multiplication traps on NaN lhs")
    func multiplyNaNLhsTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>.nan * Int64(1)
        }
    }

    @Test("Multiplication traps on NaN rhs")
    func multiplyNaNRhsTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Int64(1) * Money<TST_100>.nan
        }
    }

    // MARK: - Overflow traps

    @Test("Multiplication traps on overflow")
    func multiplyOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>.max * Int64(2)
        }
    }

    @Test("Multiplication traps on underflow")
    func multiplyUnderflowTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>.min * Int64(2)
        }
    }

    // MARK: - *= operator

    @Test("*= multiplies in place")
    func multiplyAssign() {
        var value = Money<TST_100>(minorUnits: 5)
        value *= 3
        #expect(value == Money<TST_100>(minorUnits: 15))
    }

    @Test("*= traps on NaN")
    func multiplyAssignNaNTraps() async {
        await #expect(processExitsWith: .failure) {
            var nan = Money<TST_100>.nan
            nan *= 1
        }
    }

    @Test("*= traps on overflow")
    func multiplyAssignOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            var value = Money<TST_100>.max
            value *= 2
        }
    }
}
