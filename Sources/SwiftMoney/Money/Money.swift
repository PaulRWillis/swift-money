import Foundation

public struct Money<Currency: SwiftMoney.Currency> {
    let minorUnits: Int

    /// The currency type
    public var currency: any SwiftMoney.Currency.Type {
        Currency.self
    }

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

extension Money: CustomStringConvertible {
    public var description: String {
        self.formatted()
    }
}

extension Money: Equatable {}

extension Money: Hashable {}

extension Money: Sendable {}

extension Money: Codable {}
