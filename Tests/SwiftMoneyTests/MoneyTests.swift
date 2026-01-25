import SwiftMoney
import Testing

private enum TST: Currency {}

struct MoneyTests {

    // MARK: - Addition

    @Test
    func addNonZeroToNonZero() throws {
        let a = Money<TST>(2)
        let b = Money<TST>(3)
        let expected = Money<TST>(5)
        
        let actual = a + b
        
        #expect(actual == expected)
    }
    
    @Test
    func addZeroToNonZero() throws {
        let zero = Money<TST>(0)
        let nonZero = Money<TST>(3)
        let expected = nonZero

        let actual = nonZero + zero

        #expect(actual == expected)
    }
    
    @Test
    func addNonZeroToZero() {
        let zero = Money<TST>(0)
        let nonZero = Money<TST>(3)
        let expected = nonZero

        let actual = zero + nonZero

        #expect(actual == expected)
    }

    @Test
    func addZeroToZero() {
        let zero = Money<TST>(0)

        let actual = zero + zero

        #expect(actual == zero)
    }

    // MARK: - Subtraction

    @Test
    func subtractNonZeroFromNonZero() {
        let a = Money<TST>(3)
        let b = Money<TST>(2)
        let expected = Money<TST>(1)

        let actual = a - b

        #expect(actual == expected)
    }

    @Test
    func subtractZeroFromNonZero() {
        let zero = Money<TST>(0)
        let nonZero = Money<TST>(3)
        let expected = nonZero

        let actual = nonZero - zero

        #expect(actual == expected)
    }

    @Test
    func subtractNonZeroFromZero() {
        let zero = Money<TST>(0)
        let nonZero = Money<TST>(3)
        let expected = Money<TST>(-3)

        let actual = zero - nonZero

        #expect(actual == expected)
    }

    @Test
    func subtractZeroFromZero() {
        let zero = Money<TST>(0)

        let actual = zero - zero

        #expect(actual == zero)
    }
}
