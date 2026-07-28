public struct DistributionParts: Equatable, Hashable, Sendable {
    fileprivate let rawValue: Int

    public init?(_ value: Int) {
        guard value >= 1 else {
            return nil
        }

        self.rawValue = value
    }

    internal init(unchecked value: Int) {
        self.rawValue = value
    }
}

extension DistributionParts: Comparable {
    public static func < (lhs: DistributionParts, rhs: DistributionParts) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension DistributionParts {
    func subtracting(
        _ other: DistributionParts
    ) -> DistributionParts {
        precondition(other < self, "Result must remain at least one part")

        return DistributionParts(unchecked: rawValue - other.rawValue)
    }
}

extension DistributionParts: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        precondition(value >= 1, "Value must be at least 1. Value: \(value)")

        self.rawValue = value
    }
}

public extension Int {
    init(_ parts: DistributionParts) {
        self = parts.rawValue
    }
}
