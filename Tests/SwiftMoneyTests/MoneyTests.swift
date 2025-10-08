import SwiftMoney
import Testing

private enum TST: Currency {
    public static let code: String = "TST"
}

struct MoneyTests {
    @Test
    func moneyExists() {
        let _ = Money<TST>(decimalValue: 1)
    }
    
    @Test
    func whenAddMoneysOfSameCurrency_shouldReturnSum() {
        let a = Money<TST>(decimalValue: 2)
        let b = Money<TST>(decimalValue: 3)
        let c = Money<TST>(decimalValue: 5)
        let expected = Money<TST>(decimalValue: 10)
        
        let actual = a + b + c
        
        #expect(actual == expected)
    }
    
    @Test
    func whenAddingZeroToMoneyAmount_shouldReturnSameMoneyAmount() {
        let money = Money<TST>(decimalValue: 3)
        let zero = Money<TST>(decimalValue: 0)
        let expected = money
        
        let actual = money + zero
        
        #expect(actual == expected)
    }
    
    @Test
    func whenAddingMoneyAmountToZero_shouldReturnSameMoneyAmount() {
        let zero = Money<TST>(decimalValue: 0)
        let money = Money<TST>(decimalValue: 3)
        let expected = money
        
        let actual = zero + money
        
        #expect(actual == expected)
    }
    
    @Test
    func whenAddDecimalMoneysOfSameCurrency_shouldReturnSum() {
        let a = Money<TST>(decimalValue: 0.1)
        let b = Money<TST>(decimalValue: 0.1)
        let c = Money<TST>(decimalValue: 0.1)
        let expected = Money<TST>(decimalValue: 0.3)
        
        let actual = a + b + c
        
        #expect(actual == expected)
    }
}
