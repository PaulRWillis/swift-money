import SwiftMoney
import Testing

private enum TST: Currency {}

struct MoneyTests {
    @Test
    func whenAddMoneysOfSameCurrency_shouldReturnSum() throws {
        let a = Money<TST>(2)
        let b = Money<TST>(3)
        let expected = Money<TST>(5)
        
        let actual = a + b
        
        #expect(actual == expected)
    }
    
    @Test
    func whenAddingZeroToMoneyAmount_shouldReturnSameMoneyAmount() throws {
        let money = Money<TST>(3)
        let zero = Money<TST>(0)
        let expected = money
        
        let actual = money + zero
        
        #expect(actual == expected)
    }
    
    @Test
    func whenAddingMoneyAmountToZero_shouldReturnSameMoneyAmount() throws {
        let zero = Money<TST>(0)
        let money = Money<TST>(3)
        let expected = money
        
        let actual = zero + money
        
        #expect(actual == expected)
    }

    @Test
    func whenAddingZeroToZero_shouldReturnZeroMoney() throws {
        let zero = Money<TST>(0)

        let actual = zero + zero

        #expect(actual == zero)
    }

}
