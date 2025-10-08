import SwiftMoney
import Testing

private enum TST: Currency {
    public static let code: String = "TST"
    public static let name: String = "TST Money"
    public static let minorUnit: Int = 2
}

struct MoneyTests {
    @Test
    func moneyExists() {
        let _ = Money<TST>(decimalValue: 1)
    }
    
    @Test
    func canAddMoneysOfSameCurrency() {
        let a = Money<TST>(decimalValue: 2)
        let b = Money<TST>(decimalValue: 3)
        let c = Money<TST>(decimalValue: 5)
        let expected = Money<TST>(decimalValue: 10)
        
        let actual = a + b + c
        
        #expect(actual == expected)
    }
    
    @Test
    func canAddDecimalMoneysOfSameCurrency() {
        let a = Money<TST>(decimalValue: 0.1)
        let b = Money<TST>(decimalValue: 0.1)
        let c = Money<TST>(decimalValue: 0.1)
        let expected = Money<TST>(decimalValue: 0.3)
        
        let actual = a + b + c
        
        #expect(actual == expected)
    }
    
}
