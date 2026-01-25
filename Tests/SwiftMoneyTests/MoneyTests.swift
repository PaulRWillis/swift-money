import SwiftMoney
import Testing

private enum TST: Currency {}

struct MoneyTests {

    // MARK: - ADDITION

    // MARK: - Addition (Positives)

    @Test
    func addPositiveToPositive() {
        let a = Money<TST>(2)
        let b = Money<TST>(3)
        let expected = Money<TST>(5)
        
        let actual = a + b
        
        #expect(actual == expected)
    }

    @Test
    func addPositiveToNegative() {
        let positive = Money<TST>(2)
        let negative = Money<TST>(-3)
        let expected = Money<TST>(-1)

        let actual = negative + positive

        #expect(actual == expected)
    }

    @Test
    func addPositiveToZero() {
        let zero = Money<TST>(0)
        let positive = Money<TST>(3)

        let actual = zero + positive

        #expect(actual == positive)
    }

    // MARK: Addition (Negatives)

    @Test
    func addNegativeToPositive() {
        let positive = Money<TST>(2)
        let negative = Money<TST>(-3)
        let expected = Money<TST>(-1)

        let actual = positive + negative

        #expect(actual == expected)
    }

    @Test
    func addNegativeToNegative() {
        let a = Money<TST>(-2)
        let b = Money<TST>(-3)
        let expected = Money<TST>(-5)

        let actual = a + b

        #expect(actual == expected)
    }

    @Test
    func addNegativeToZero() {
        let zero = Money<TST>(0)
        let negative = Money<TST>(-1)

        let actual = zero + negative

        #expect(actual == negative)
    }

    // MARK: Addition (Zero)

    @Test
    func addZeroToPositive() {
        let zero = Money<TST>(0)
        let positive = Money<TST>(3)

        let actual = positive + zero

        #expect(actual == positive)
    }

    @Test
    func addZeroToNegative() {
        let zero = Money<TST>(0)
        let negative = Money<TST>(-1)

        let actual = negative + zero

        #expect(actual == negative)
    }

    @Test
    func addZeroToZero() {
        let zero = Money<TST>(0)

        let actual = zero + zero

        #expect(actual == zero)
    }

    // MARK: - SUBTRACTION

    // MARK: Subtraction (Positive)

    @Test
    func subtractPositiveFromPositive() {
        let a = Money<TST>(3)
        let b = Money<TST>(2)
        let expected = Money<TST>(1)

        let actual = a - b

        #expect(actual == expected)
    }

    @Test
    func subtractPositiveFromNegative() {
        let positive = Money<TST>(7)
        let negative = Money<TST>(-3)
        let expected = Money<TST>(-10)

        let actual = negative - positive

        #expect(actual == expected)
    }

    @Test
    func subtractPositiveFromZero() {
        let zero = Money<TST>(0)
        let positive = Money<TST>(3)
        let expected = Money<TST>(-3)

        let actual = zero - positive

        #expect(actual == expected)
    }

    // MARK: - Subtraction (Negative)

    @Test
    func subtractNegativeFromPositive() {
        let positive = Money<TST>(4)
        let negative = Money<TST>(-3)
        let expected = Money<TST>(7)

        let actual = positive - negative

        #expect(actual == expected)
    }

    @Test
    func subtractNegativeFromNegative() {
        let a = Money<TST>(-3)
        let b = Money<TST>(-4)
        let expected = Money<TST>(1)

        let actual = a - b

        #expect(actual == expected)
    }

    @Test
    func subtractNegativeFromZero() {
        let zero = Money<TST>(0)
        let negative = Money<TST>(-9)
        let expected = Money<TST>(9)

        let actual = zero - negative

        #expect(actual == expected)
    }

    // MARK: - Subtraction (Zero)

    @Test
    func subtractZeroFromPositive() {
        let zero = Money<TST>(0)
        let positive = Money<TST>(3)

        let actual = positive - zero

        #expect(actual == positive)
    }

    @Test
    func subtractZeroFromNegative() {
        let zero = Money<TST>(0)
        let negative = Money<TST>(-7)

        let actual = negative - zero

        #expect(actual == negative)
    }

    @Test
    func subtractZeroFromZero() {
        let zero = Money<TST>(0)

        let actual = zero - zero

        #expect(actual == zero)
    }

    // MARK: - MULTIPLICATION

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
