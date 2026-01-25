import SwiftMoney
import Testing

private enum TST: Currency {}

struct MoneyTests {
    @Test
    func whenAddMoneysOfSameCurrency_shouldReturnSum() throws {
        let a = try #require(Money<TST>(string: "2"))
        let b = try #require(Money<TST>(string: "3"))
        let expected = try #require(Money<TST>(string: "5"))
        
        let actual = a + b
        
        #expect(actual == expected)
    }
    
    @Test
    func whenAddingZeroToMoneyAmount_shouldReturnSameMoneyAmount() throws {
        let money = try #require(Money<TST>(string: "3"))
        let zero = try #require(Money<TST>(string: "0"))
        let expected = money
        
        let actual = money + zero
        
        #expect(actual == expected)
    }
    
    @Test
    func whenAddingMoneyAmountToZero_shouldReturnSameMoneyAmount() throws {
        let zero = try #require(Money<TST>(string: "0"))
        let money = try #require(Money<TST>(string: "3"))
        let expected = money
        
        let actual = zero + money
        
        #expect(actual == expected)
    }
}
