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
    static func * (lhs: Money, rhs: Int) -> Money {
        Money(minorUnits: lhs._minorUnits * rhs)
    }

    static func * (lhs: Int, rhs: Money) -> Money {
        Money(minorUnits: lhs * rhs._minorUnits)
    }
}
