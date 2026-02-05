import Foundation

public struct Money<C: Currency> {
    private let minorUnits: Int

    public init(minorUnits: Int) {
        self.minorUnits = minorUnits
    }
}

public extension Money {
    static func + (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs.minorUnits + rhs.minorUnits)
    }
}

public extension Money {
    static func - (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs.minorUnits - rhs.minorUnits)
    }
}

public extension Money {
    static func * (lhs: Money, rhs: Int) -> Money {
        Money(minorUnits: lhs.minorUnits * rhs)
    }

    static func * (lhs: Int, rhs: Money) -> Money {
        Money(minorUnits: lhs * rhs.minorUnits)
    }
}

extension Money: Equatable {}

extension Money: Hashable {}

extension Money: Sendable {}

extension Money: Codable {}
