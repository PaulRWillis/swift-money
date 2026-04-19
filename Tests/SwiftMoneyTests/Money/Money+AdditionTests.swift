import SwiftMoney
import Testing

struct Money_AdditionTests {

    // MARK: - Addition (Positives)

    @Test("Addition of positive values")
    func addPositive() {
        let a = Money<TST>(minorUnits: 2)
        let b = Money<TST>(minorUnits: 3)

        let actual = a + b

        #expect(actual == Money<TST>(minorUnits: 5))
    }

    @Test("Addition of positive to negative")
    func addPositiveToNegative() {
        let positive = Money<TST>(minorUnits: 2)
        let negative = Money<TST>(minorUnits: -3)

        let actual = negative + positive

        #expect(actual == Money<TST>(minorUnits: -1))
    }

    @Test("Addition of positive to zero")
    func addPositiveToZero() {
        let zero = Money<TST>(minorUnits: 0)
        let positive = Money<TST>(minorUnits: 3)

        let actual = zero + positive

        #expect(actual == positive)
    }

    // MARK: Addition (Negatives)

    @Test("Addition of negative to positive")
    func addNegativeToPositive() {
        let positive = Money<TST>(minorUnits: 2)
        let negative = Money<TST>(minorUnits: -3)

        let actual = positive + negative

        #expect(actual == Money<TST>(minorUnits: -1))
    }

    @Test("Addition of negative values")
    func addNegativeToNegative() {
        let a = Money<TST>(minorUnits: -2)
        let b = Money<TST>(minorUnits: -3)

        let actual = a + b

        #expect(actual == Money<TST>(minorUnits: -5))
    }

    @Test("Addition of negative to zero")
    func addNegativeToZero() {
        let zero = Money<TST>(minorUnits: 0)
        let negative = Money<TST>(minorUnits: -1)

        let actual = zero + negative

        #expect(actual == negative)
    }

    // MARK: Addition (Zero)

    @Test("Addition of zero to positive")
    func addZeroToPositive() {
        let zero = Money<TST>(minorUnits: 0)
        let positive = Money<TST>(minorUnits: 3)

        let actual = positive + zero

        #expect(actual == positive)
    }

    @Test("Addition of zero to negative")
    func addZeroToNegative() {
        let zero = Money<TST>(minorUnits: 0)
        let negative = Money<TST>(minorUnits: -1)

        let actual = negative + zero

        #expect(actual == negative)
    }

    @Test("Addition of zero values")
    func addZeroToZero() {
        let zero = Money<TST>(minorUnits: 0)

        let actual = zero + zero

        #expect(actual == zero)
    }
}
