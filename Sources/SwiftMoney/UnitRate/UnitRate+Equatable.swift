// MARK: - Equatable

extension UnitRate: Equatable {
    public static func == (lhs: UnitRate, rhs: UnitRate) -> Bool {
        lhs.rate == rhs.rate && lhs.unit == rhs.unit
    }
}

// MARK: - Hashable

extension UnitRate: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rate)
        hasher.combine(unit)
    }
}
