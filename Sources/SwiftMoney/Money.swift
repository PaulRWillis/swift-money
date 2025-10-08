import Foundation

public struct Money<C: Currency> {
    private let amount: Decimal
    
    public init(decimalValue: Decimal) {
        self.amount = decimalValue
    }
}

public extension Money {
    static func + (lhs: Money, rhs: Money) -> Money {
        Money(decimalValue: lhs.amount + rhs.amount)
    }
}

extension Money: Equatable {}
