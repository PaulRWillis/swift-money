import Foundation

public struct Money<C: Currency> {
    private let minorUnits: Int
    
    public init(_ intValue: Int) {
        self.minorUnits = intValue
    }
}

public extension Money {
    static func + (lhs: Money, rhs: Money) -> Money {
        Money(lhs.minorUnits + rhs.minorUnits)
    }
}

extension Money: Equatable {}
