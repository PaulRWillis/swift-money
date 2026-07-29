public struct PartCount: Equatable, Hashable, Sendable {
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

extension PartCount: Comparable {
    public static func < (lhs: PartCount, rhs: PartCount) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension PartCount {
    func subtracting(
        _ other: PartCount
    ) -> PartCount {
        precondition(other < self, "Result must remain at least one part")

        return PartCount(unchecked: rawValue - other.rawValue)
    }
}

extension PartCount: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        precondition(value >= 1, "Value must be at least 1. Value: \(value)")

        self.rawValue = value
    }
}

public extension Int {
    init(_ parts: PartCount) {
        self = parts.rawValue
    }
}
