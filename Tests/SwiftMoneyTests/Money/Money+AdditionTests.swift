import SwiftMoney
import Testing

struct Money_AdditionTests {

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
}
