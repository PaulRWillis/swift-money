import Foundation

public struct Money<C: Currency> {
    private let minorUnits: Int
    
    private init(intValue: Int) {
        self.minorUnits = intValue
    }
    
    public init?(string: String) {
        guard let intValue = Int(string) else {
            return nil
        }
        
        self.minorUnits = intValue
    }
}

public extension Money {
    static func + (lhs: Money, rhs: Money) -> Money {
        Money(intValue: lhs.minorUnits + rhs.minorUnits)
    }
}

extension Money: Equatable {}
