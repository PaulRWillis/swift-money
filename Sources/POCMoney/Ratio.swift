/// An exact fraction, used to scale a monetary amount.
///
/// Stored in lowest terms with the sign on the numerator, so equivalent fractions are the same value:
/// `Ratio(22, 200)` and `Ratio(11, 100)` are equal.
///
/// ```swift
/// let vat = Ratio(7, 40)   // 17.5%
/// ```
///
/// Exact, unlike a decimal or floating-point rate — one third is `Ratio(1, 3)` and stays one third.
public struct Ratio: Equatable, Hashable, Sendable {
    private let numerator: Numerator
    private let denominator: Denominator

    /// Creates a ratio, reduced to lowest terms.
    ///
    /// - Parameters:
    ///   - numerator: The signed part. Any value is valid.
    ///   - denominator: The part below the line. Always positive, which the type guarantees.
    public init(
        _ numerator: Numerator,
        _ denominator: Denominator
    ) {
        let rawNumerator = Int64(numerator)
        let rawDenominator = Int64(denominator)

        // Reduce on magnitudes: `abs(Int64.min)` overflows, but its magnitude fits in `UInt64`. The
        // divisor cannot exceed the denominator, so converting it back to `Int64` is always safe, and
        // dividing by a positive value means `Int64.min / -1` — the one trapping division — cannot
        // arise.
        let divisor = Int64(greatestCommonDivisor(rawNumerator.magnitude, rawDenominator.magnitude))

        self.numerator = Numerator(rawNumerator / divisor)
        self.denominator = Denominator(unchecked: rawDenominator / divisor)
    }
}

// MARK: - CustomStringConvertible

extension Ratio: CustomStringConvertible {
    public var description: String {
        "\(Int64(numerator))/\(Int64(denominator))"
    }
}

// MARK: - Operands

public extension Ratio {
    /// The signed part of a ratio.
    ///
    /// Every integer is a valid numerator, so this cannot fail to be created — including from a
    /// literal, unlike ``Ratio/Denominator``.
    struct Numerator: Equatable, Hashable, Sendable {
        fileprivate let rawValue: Int64

        /// Creates a numerator.
        public init(_ value: Int64) {
            self.rawValue = value
        }
    }

    /// A positive integer, used as the denominator of a ratio.
    ///
    /// A ratio's sign is carried entirely by its numerator, so a denominator is never zero or
    /// negative. Those values cannot be constructed.
    struct Denominator: Equatable, Hashable, Sendable {
        fileprivate let rawValue: Int64

        /// Creates a denominator from a value that may not be valid.
        ///
        /// - Parameter value: The denominator.
        /// - Returns: `nil` if `value` is less than one.
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
}

// MARK: - Literals

extension Ratio.Numerator: ExpressibleByIntegerLiteral {
    /// Creates a numerator from an integer literal.
    ///
    /// - Parameter value: The numerator.
    public init(integerLiteral value: Int64) {
        self.rawValue = value
    }
}

extension Ratio.Denominator: ExpressibleByIntegerLiteral {
    /// Creates a denominator from an integer literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so a value below one is a
    /// mistake in the source rather than bad input — it traps instead of failing gracefully. Use
    /// ``init(exactly:)`` for any value that is not a literal.
    ///
    /// ```swift
    /// let fortieths: Ratio.Denominator = 40   // fine
    /// let none: Ratio.Denominator = 0         // traps
    /// ```
    ///
    /// - Parameter value: The denominator.
    /// - Precondition: `value` is at least one.
    public init(integerLiteral value: Int64) {
        precondition(value >= 1, "A denominator must be at least 1. Value: \(value)")

        self.rawValue = value
    }
}

// MARK: - Conversions

public extension Int64 {
    /// Creates an integer from a ratio's numerator.
    init(_ numerator: Ratio.Numerator) {
        self = numerator.rawValue
    }

    /// Creates an integer from a ratio's denominator.
    init(_ denominator: Ratio.Denominator) {
        self = denominator.rawValue
    }
}
