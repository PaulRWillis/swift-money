import SwiftMoney
import Testing

struct Money_AdditionTests {

    // MARK: - Addition (Positives)

    @Test("Addition of positive values")
    func addPositive() {
        let a: Money<TST> = 2
        let b: Money<TST> = 3
        #expect(a + b == 5)
    }

    @Test("Addition of positive to negative")
    func addPositiveToNegative() {
        let neg: Money<TST> = -3
        let pos: Money<TST> = 2
        #expect(neg + pos == -1)
    }

    @Test("Addition of positive to zero")
    func addPositiveToZero() {
        let pos = Money<TST>(minorUnits: 3)
        #expect(.zero + pos == pos)
    }

    // MARK: Addition (Negatives)

    @Test("Addition of negative to positive")
    func addNegativeToPositive() {
        let pos: Money<TST> = 2
        let neg: Money<TST> = -3
        #expect(pos + neg == -1)
    }

    @Test("Addition of negative values")
    func addNegativeToNegative() {
        let a: Money<TST> = -2
        let b: Money<TST> = -3
        #expect(a + b == -5)
    }

    @Test("Addition of negative to zero")
    func addNegativeToZero() {
        let neg: Money<TST> = -1
        #expect(.zero + neg == neg)
    }

    // MARK: Addition (Zero)

    @Test("Addition of zero to positive")
    func addZeroToPositive() {
        let pos: Money<TST> = 3
        #expect(pos + .zero == pos)
    }

    @Test("Addition of zero to negative")
    func addZeroToNegative() {
        let neg: Money<TST> = -1
        #expect(neg + .zero == neg)
    }

    @Test("Addition of zero values")
    func addZeroToZero() {
        #expect(Money<TST>.zero + .zero == .zero)
    }

    // MARK: Addition assignment

    @Test("Addition assignment")
    func addAssign() {
        var a: Money<TST> = 100
        a += 5
        #expect(a == 105)
    }

    @Test("Addition assignment of negative")
    func addAssignNegative() {
        var a: Money<TST> = 100
        a += -5
        #expect(a == 95)
    }

    @Test("Addition assignment of two negatives")
    func addAssignTwoNegatives() {
        var a: Money<TST> = -50
        a += -5
        #expect(a == -55)
    }
}
