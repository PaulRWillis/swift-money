public extension Money {
    static func + (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs._minorUnits + rhs._minorUnits)
    }
}

public extension Money {
    static func - (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs._minorUnits - rhs._minorUnits)
    }
}

public extension Money {
    static func * (lhs: Money, rhs: Int64) -> Money {
        Money(minorUnits: lhs._minorUnits * rhs)
    }

    static func * (lhs: Int64, rhs: Money) -> Money {
        Money(minorUnits: lhs * rhs._minorUnits)
    }
}
