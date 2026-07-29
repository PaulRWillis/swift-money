/// The number of parts an amount is split into.
///
/// Always at least one. Splitting into zero or a negative number of parts has no meaning, so those
/// values cannot be constructed.
public struct PartCount: Equatable, Hashable, Sendable {
    fileprivate let rawValue: Int

    /// Creates a part count from a value that may not be valid.
    ///
    /// - Parameter value: The number of parts.
    /// - Returns: `nil` if `value` is less than one.
    public init?(exactly value: Int) {
        guard value >= 1 else {
            return nil
        }

        self.rawValue = value
    }

    // No check: only for call sites that have already established the value is at least one.
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
    // Precondition: `other` is smaller than `self`, so at least one part remains.
    func subtracting(
        _ other: PartCount
    ) -> PartCount {
        precondition(other < self, "Result must remain at least one part")

        return PartCount(unchecked: rawValue - other.rawValue)
    }
}

extension PartCount: ExpressibleByIntegerLiteral {
    /// Creates a part count from an integer literal.
    ///
    /// ```swift
    /// let parts: PartCount = 3    // fine
    /// let none: PartCount = 0     // traps
    /// let same = PartCount(0)     // traps — also a literal, despite the call syntax
    /// ```
    ///
    /// - Parameter value: The number of parts.
    /// - Precondition: `value` is at least one.
    public init(integerLiteral value: Int) {
        precondition(value >= 1, "Value must be at least 1. Value: \(value)")

        self.rawValue = value
    }
}

public extension Int {
    /// Creates an integer from a part count.
    ///
    /// - Parameter parts: The part count to convert.
    init(_ parts: PartCount) {
        self = parts.rawValue
    }
}
