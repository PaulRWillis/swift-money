import Foundation

public struct Money<C: Currency> {
    private let amount: Decimal
    
    private init(decimal: Decimal) {
        self.amount = decimal
    }
    
    public init?(string: String, locale: Locale? = nil) {
        guard let decimalValue = Decimal(string: string, locale: locale) else {
            return nil
        }
        
        self.amount = decimalValue
    }
}

public extension Money {
    static func + (lhs: Money, rhs: Money) -> Money {
        Money(decimal: lhs.amount + rhs.amount)
    }
}

extension Money: Equatable {}
