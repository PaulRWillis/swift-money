import SwiftMoney
import Testing

private enum TST: Currency {
    public static let code: String = "TST"
}

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
    
    @Test
    func whenAddDecimalMoneysOfSameCurrency_shouldReturnSum() throws {
        let a = try #require(Money<TST>(string: "0.1"))
        let b = try #require(Money<TST>(string: "0.1"))
        let c = try #require(Money<TST>(string: "0.1"))
        let expected = try #require(Money<TST>(string: "0.3"))
        
        let actual = a + b + c
        
        #expect(actual == expected)
    }
}
