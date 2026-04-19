import SwiftMoney
import Testing

struct Money_SubtractionTests {

    // MARK: Subtraction (Positive)

    @Test("Subtraction of positive values")
    func subtractPositiveFromPositive() {
        let a: Money<TST> = 3
        let b: Money<TST> = 2
        #expect(a - b == 1)
    }

    @Test("Subtraction of positive from negative")
    func subtractPositiveFromNegative() {
        let pos: Money<TST> = 7
        let neg: Money<TST> = -3
        #expect(neg - pos == -10)
    }

    @Test("Subtraction of positive from zero")
    func subtractPositiveFromZero() {
        let pos: Money<TST> = 3
        #expect(.zero - pos == -3)
    }

    // MARK: - Subtraction (Negative)

    @Test("Subtraction of negative from positive")
    func subtractNegativeFromPositive() {
        let pos: Money<TST> = 4
        let neg: Money<TST> = -3
        #expect(pos - neg == 7)
    }

    @Test("Subtraction of negative values")
    func subtractNegativeFromNegative() {
        let a: Money<TST> = -3
        let b: Money<TST> = -4
        #expect(a - b == 1)
    }

    @Test("Subtration of negative from zero")
    func subtractNegativeFromZero() {
        let neg: Money<TST> = -9
        #expect(.zero - neg == 9)
    }

    // MARK: - Subtraction (Zero)

    @Test("Subtraction of zero from positive")
    func subtractZeroFromPositive() {
        let pos: Money<TST> = 3
        #expect(pos - .zero == pos)
    }

    @Test("Subtraction of zero from negative")
    func subtractZeroFromNegative() {
        let neg: Money<TST> = -7
        #expect(neg - .zero == neg)
    }

    @Test("Subtraction of zero values")
    func subtractZeroFromZero() {
        #expect(Money<TST>.zero - .zero == .zero)
    }

    // MARK: Subtraction assignment

    @Test("Subtraction assignment")
    func subtractAssign() {
        var a: Money<TST> = 15
        a -= 4
        #expect(a == 11)
    }

    @Test("Subtraction assignment of negative")
    func subtractAssignNegative() {
        var a: Money<TST> = 112
        a -= -5
        #expect(a == 117)
    }

    @Test("Subtraction assignment of two negatives")
    func subtractAssignTwoNegatives() {
        var a: Money<TST> = -50
        a -= -5
        #expect(a == -45)
    }
}
