import SwiftMoney
import Testing

struct Money_IntegralMultiplicationTests {

    // MARK: - Integral multiplication (Positive)

    @Test
    func multiplyPositiveMoneyByPositiveInt() {
        let positiveMoney = Money<TST>(2)
        let positiveInt: Int = 3
        let expected = Money<TST>(6)

        let actual = positiveMoney * positiveInt

        #expect(actual == expected)
    }

    @Test
    func multiplyPositiveMoneyByNegativeInt() {
        let positiveMoney = Money<TST>(2)
        let negativeInt: Int = -3
        let expected = Money<TST>(-6)

        let actual = positiveMoney * negativeInt

        #expect(actual == expected)
    }

    @Test
    func multiplyPositiveMoneyByZeroInt() {
        let zeroMoney = Money<TST>(0)
        let positiveInt: Int = 5

        let actual =  positiveInt * zeroMoney

        #expect(actual == zeroMoney)
    }

    // MARK: - Integral multiplication (negative)

    @Test
    func multiplyNegativeMoneyByPositiveInt() {
        let negativeMoney = Money<TST>(-2)
        let positiveInt: Int = 3
        let expected = Money<TST>(-6)

        let actual = negativeMoney * positiveInt

        #expect(actual == expected)
    }

    @Test
    func multiplyNegativeMoneyByNegativeInt() {
        let negativeMoney = Money<TST>(-3)
        let negativeInt: Int = -4
        let expected = Money<TST>(12)

        let actual = negativeMoney * negativeInt

        #expect(actual == expected)
    }

    @Test
    func multiplyNegativeIntByZeroMoney() {
        let zeroMoney = Money<TST>(0)
        let negativeInt: Int = -5

        let actual =  negativeInt * zeroMoney

        #expect(actual == zeroMoney)
    }

    // MARK: - Integral multiplication (zero)

    @Test
    func multiplyZeroMoneyByPositiveInt() {
        let zeroMoney = Money<TST>(0)
        let positiveInt: Int = 5

        let actual = zeroMoney * positiveInt

        #expect(actual == zeroMoney)
    }

    @Test
    func multiplyZeroMoneyByNegativeInt() {
        let zeroMoney = Money<TST>(0)
        let negativeInt: Int = -2

        let actual = zeroMoney * negativeInt

        #expect(actual == zeroMoney)
    }

    @Test
    func multiplyZeroMoneyByZeroInt() {
        let zeroMoney = Money<TST>(0)
        let zeroInt = Int.zero

        let actual = zeroMoney * zeroInt

        #expect(actual == zeroMoney)
    }
}
