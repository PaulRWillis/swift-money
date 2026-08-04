/// How many of a currency's smallest units make one major unit.
///
/// `100` for pounds and euros, `1` for yen, `100_000_000` for bitcoin.
///
/// Always positive. Any positive value is allowed, not only powers of ten: the ouguiya divides into
/// five khoums and the ariary into five iraimbilanja, and a currency with three named tiers — such as
/// pre-decimal sterling, at twenty shillings of twelve pence — is `240`.
public struct MinimalQuantization: Equatable, Hashable, Sendable {
    fileprivate let rawValue: Int64

    /// Creates a quantization from a value that may not be valid.
    ///
    /// - Parameter value: The number of smallest units per major unit.
    /// - Returns: `nil` if `value` is zero or negative.
    public init?(exactly value: Int64) {
        guard value >= 1 else {
            return nil
        }

        self.rawValue = value
    }

    // No check: only for call sites that have already established the value is positive.
    internal init(unchecked value: Int64) {
        self.rawValue = value
    }
}

extension MinimalQuantization: ExpressibleByIntegerLiteral {
    /// Creates a quantization from an integer literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so a value below one is a
    /// mistake in the source rather than bad input — it traps instead of failing gracefully. Use
    /// ``init(exactly:)`` for any value that is not a literal.
    ///
    /// ```swift
    /// let pence: MinimalQuantization = 100    // fine
    /// let none: MinimalQuantization = 0       // traps
    /// ```
    ///
    /// - Parameter value: The number of smallest units per major unit.
    /// - Precondition: `value` is at least one.
    public init(integerLiteral value: Int64) {
        precondition(value >= 1, "Quantization must be at least 1. Value: \(value)")

        self.rawValue = value
    }
}

public extension Int64 {
    /// Creates an integer from a quantization.
    init(_ quantization: MinimalQuantization) {
        self = quantization.rawValue
    }
}
