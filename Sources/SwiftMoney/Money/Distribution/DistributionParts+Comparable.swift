// MARK: - Equatable

extension DistributionParts: Equatable {
    public static func == (lhs: DistributionParts, rhs: DistributionParts) -> Bool {
        lhs._value == rhs._value
    }
}

// MARK: - Hashable

extension DistributionParts: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_value)
    }
}

// MARK: - Comparable

extension DistributionParts: Comparable {
    public static func < (lhs: DistributionParts, rhs: DistributionParts) -> Bool {
        lhs._value < rhs._value
    }
}
