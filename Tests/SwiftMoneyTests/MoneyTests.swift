import SwiftMoney
import Testing

private enum TST: Currency {}

struct MoneyTests {

    // MARK: - ADDITION

    // MARK: - Addition (Positives)
    @Test
    func addPositiveToPositive() throws {
        let a = Money<TST>(2)
        let b = Money<TST>(3)
        let expected = Money<TST>(5)
        
        let actual = a + b
        
        #expect(actual == expected)
    }
    
    @Test
    func addZeroToPositive() throws {
        let zero = Money<TST>(0)
        let positive = Money<TST>(3)

        let actual = positive + zero

        #expect(actual == positive)
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
    func addNegativeToNegative() {
        let a = Money<TST>(-2)
        let b = Money<TST>(-3)
        let expected = Money<TST>(-5)

        let actual = a + b

        #expect(actual == expected)
    }

    @Test
    func addZeroToNegative() {
        let zero = Money<TST>(0)
        let negative = Money<TST>(-1)

        let actual = negative + zero

        #expect(actual == negative)
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
    func subtractZeroFromPositive() {
        let zero = Money<TST>(0)
        let positive = Money<TST>(3)

        let actual = positive - zero

        #expect(actual == positive)
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
    func subtractNegativeFromNegative() {
        let a = Money<TST>(-3)
        let b = Money<TST>(-4)
        let expected = Money<TST>(1)

        let actual = a - b

        #expect(actual == expected)
    }

    @Test
    func subtractZeroFromNegative() {
        let zero = Money<TST>(0)
        let negative = Money<TST>(-7)

        let actual = negative - zero

        #expect(actual == negative)
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
    func multiplyZeroMoneyByPositiveInt() {
        let zeroMoney = Money<TST>(0)
        let positiveInt: Int = 5
        
        let actual = zeroMoney * positiveInt
        
        #expect(actual == zeroMoney)
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
    func multiplyNegativeMoneyByNegativeInt() {
        let negativeMoney = Money<TST>(-3)
        let negativeInt: Int = -4
        let expected = Money<TST>(12)

        let actual = negativeMoney * negativeInt

        #expect(actual == expected)
    }

    @Test
    func multiplyZeroMoneyByNegativeInt() {
        let zeroMoney = Money<TST>(0)
        let negativeInt: Int = -2

        let actual = zeroMoney * negativeInt

        #expect(actual == zeroMoney)
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
    func multiplyZeroMoneyByZeroInt() {
        let zeroMoney = Money<TST>(0)
        let zeroInt = Int.zero

        let actual = zeroMoney * zeroInt

        #expect(actual == zeroMoney)
    }
}
