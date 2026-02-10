import SwiftMoney
import Testing

struct Money_SubtractionTests {

    // MARK: Subtraction (Positive)

    @Test
    func subtractPositiveFromPositive() {
        let a = Money<TST>(minorUnits: 3)
        let b = Money<TST>(minorUnits: 2)
        let expected = Money<TST>(minorUnits: 1)

        let actual = a - b

        #expect(actual == expected)
    }

    @Test
    func subtractPositiveFromNegative() {
        let positive = Money<TST>(minorUnits: 7)
        let negative = Money<TST>(minorUnits: -3)
        let expected = Money<TST>(minorUnits: -10)

        let actual = negative - positive

        #expect(actual == expected)
    }

    @Test
    func subtractPositiveFromZero() {
        let zero = Money<TST>(minorUnits: 0)
        let positive = Money<TST>(minorUnits: 3)
        let expected = Money<TST>(minorUnits: -3)

        let actual = zero - positive

        #expect(actual == expected)
    }

    // MARK: - Subtraction (Negative)

    @Test
    func subtractNegativeFromPositive() {
        let positive = Money<TST>(minorUnits: 4)
        let negative = Money<TST>(minorUnits: -3)
        let expected = Money<TST>(minorUnits: 7)

        let actual = positive - negative

        #expect(actual == expected)
    }

    @Test
    func subtractNegativeFromNegative() {
        let a = Money<TST>(minorUnits: -3)
        let b = Money<TST>(minorUnits: -4)
        let expected = Money<TST>(minorUnits: 1)

        let actual = a - b

        #expect(actual == expected)
    }

    @Test
    func subtractNegativeFromZero() {
        let zero = Money<TST>(minorUnits: 0)
        let negative = Money<TST>(minorUnits: -9)
        let expected = Money<TST>(minorUnits: 9)

        let actual = zero - negative

        #expect(actual == expected)
    }

    // MARK: - Subtraction (Zero)

    @Test
    func subtractZeroFromPositive() {
        let zero = Money<TST>(minorUnits: 0)
        let positive = Money<TST>(minorUnits: 3)

        let actual = positive - zero

        #expect(actual == positive)
    }

    @Test
    func subtractZeroFromNegative() {
        let zero = Money<TST>(minorUnits: 0)
        let negative = Money<TST>(minorUnits: -7)

        let actual = negative - zero

        #expect(actual == negative)
    }

    @Test
    func subtractZeroFromZero() {
        let zero = Money<TST>(minorUnits: 0)

        let actual = zero - zero

        #expect(actual == zero)
    }
}
