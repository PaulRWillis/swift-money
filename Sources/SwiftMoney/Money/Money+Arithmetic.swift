public extension Money {
    static func + (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs._storage + rhs._storage)
    }
}

public extension Money {
    static func - (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs._storage - rhs._storage)
    }
}

public extension Money {
    static func * (lhs: Money, rhs: Int64) -> Money {
        Money(minorUnits: lhs._storage * rhs)
    }

    static func * (lhs: Int64, rhs: Money) -> Money {
        Money(minorUnits: lhs * rhs._storage)
    }
}
