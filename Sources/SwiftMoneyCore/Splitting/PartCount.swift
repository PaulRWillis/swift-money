/// The number of parts an amount is split into.
///
/// Always at least one. Splitting into zero or a negative number of parts has no meaning, so those
/// values cannot be constructed.
public struct PartCount: Equatable, Hashable, Sendable {
    /// The number of parts, at least one.
    @usableFromInline let rawValue: Int

    /// Creates a part count, or `nil` if the value is less than one.
    ///
    /// ```swift
    /// PartCount(exactly: 3)    // Optional(3)
    /// PartCount(exactly: 0)    // nil
    /// ```
    ///
    /// - Parameter value: The number of parts.
    /// - Returns: A part count of `value`, or `nil` if `value` is less than one.
    public init?(exactly value: Int) {
        guard value >= 1 else {
            return nil
        }

        self.rawValue = value
    }

    /// Creates a part count without checking the value.
    ///
    /// - Parameter value: The number of parts, which the caller has checked is at least one.
    @usableFromInline init(unchecked value: Int) {
        self.rawValue = value
    }
}

extension PartCount: Comparable {
    /// Returns whether a part count is less than another.
    ///
    /// ```swift
    /// let two: PartCount = 2
    /// let three: PartCount = 3
    /// two < three    // true
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A part count to compare.
    ///   - rhs: Another part count to compare.
    /// - Returns: `true` if `lhs` is less than `rhs`; otherwise, `false`.
    public static func < (lhs: PartCount, rhs: PartCount) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension PartCount {
    /// Returns the parts left after removing some.
    ///
    /// - Parameters:
    ///   - lhs: The number of parts.
    ///   - rhs: The number of parts to remove.
    /// - Returns: The difference of `lhs` and `rhs`.
    /// - Precondition: `rhs` must be less than `lhs`.
    static func - (
        lhs: PartCount,
        rhs: PartCount
    ) -> PartCount {
        precondition(rhs < lhs, "Result must remain at least one part")

        return PartCount(unchecked: lhs.rawValue - rhs.rawValue)
    }
}

extension PartCount: ExpressibleByIntegerLiteral {
    /// Creates a part count from an integer literal.
    ///
    /// ```swift
    /// let parts: PartCount = 3    // 3
    /// let none: PartCount = 0     // traps
    /// let same = PartCount(0)     // traps: also a literal, despite the call syntax
    /// ```
    ///
    /// - Parameter value: The number of parts.
    /// - Precondition: `value` must be at least one.
    public init(integerLiteral value: Int) {
        precondition(value >= 1, "Value must be at least 1. Value: \(value)")

        self.rawValue = value
    }
}

public extension Int {
    /// Creates an integer from a part count.
    ///
    /// ```swift
    /// let parts: PartCount = 3
    /// Int(parts)    // 3
    /// ```
    ///
    /// - Parameter parts: The part count to convert.
    @inlinable
    init(_ parts: PartCount) {
        self = parts.rawValue
    }
}

public extension Int64 {
    /// Creates an integer from a part count.
    ///
    /// ```swift
    /// let parts: PartCount = 3
    /// Int64(parts)    // 3
    /// ```
    ///
    /// - Parameter parts: The part count to convert.
    init(_ parts: PartCount) {
        self = Int64(Int(parts))
    }
}
