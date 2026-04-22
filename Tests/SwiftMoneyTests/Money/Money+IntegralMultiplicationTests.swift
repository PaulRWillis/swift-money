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
}
