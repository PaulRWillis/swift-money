import SwiftMoney
import Testing

struct Money_SubtractionTests {

    // MARK: Subtraction (Positive)

    @Test
    func subtractPositiveFromPositive() {
        let a: Money<TST> = 3
        let b: Money<TST> = 2
        #expect(a - b == 1)
    }

    @Test
    func subtractPositiveFromNegative() {
        let pos: Money<TST> = 7
        let neg: Money<TST> = -3
        #expect(neg - pos == -10)
    }

    @Test
    func subtractPositiveFromZero() {
        let pos: Money<TST> = 3
        #expect(.zero - pos == -3)
    }

    // MARK: - Subtraction (Negative)

    @Test
    func subtractNegativeFromPositive() {
        let pos: Money<TST> = 4
        let neg: Money<TST> = -3
        #expect(pos - neg == 7)
    }

    @Test
    func subtractNegativeFromNegative() {
        let a: Money<TST> = -3
        let b: Money<TST> = -4
        #expect(a - b == 1)
    }

    @Test
    func subtractNegativeFromZero() {
        let neg: Money<TST> = -9
        #expect(.zero - neg == 9)
    }

    // MARK: - Subtraction (Zero)

    @Test
    func subtractZeroFromPositive() {
        let pos: Money<TST> = 3
        #expect(pos - .zero == pos)
    }

    @Test
    func subtractZeroFromNegative() {
        let neg: Money<TST> = -7
        #expect(neg - .zero == neg)
    }

    @Test
    func subtractZeroFromZero() {
        #expect(Money<TST>.zero - .zero == .zero)
    }
}
