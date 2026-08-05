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
        let divisor = Self.greatestCommonDivisor(of: numerator, and: denominator)

        self.numerator = numerator.reduced(by: divisor)
        self.denominator = denominator.reduced(by: divisor)
    }

    // Euclid, on magnitudes. `abs(Int64.min)` overflows, but `Int64.min.magnitude` is 2^63 and fits in
    // `UInt64` comfortably.
    //
    // The result is a valid `Denominator` by construction: it divides the denominator, which is at
    // least 1, so the result is between 1 and the denominator inclusive. That also means it can never
    // be zero, so this needs none of the "return 1 if both inputs were zero" guard a general-purpose
    // greatest common divisor requires.
    private static func greatestCommonDivisor(
        of numerator: Numerator,
        and denominator: Denominator
    ) -> Denominator {
        var a = numerator.rawValue.magnitude
        var b = denominator.rawValue.magnitude

        while b != 0 {
            (a, b) = (b, a % b)
        }

        return Denominator(unchecked: Int64(a))
    }
}

// MARK: - Application

internal extension Ratio {
    // The whole part of `amount` multiplied by this fraction, truncated toward zero, together with
    // whatever fraction is left over. The remainder carries the same sign as the whole part, so the two
    // account for the exact product between them.
    //
    // `nil` when the whole part is not representable as an `Int`.
    func applied(to amount: Int) -> Scaled<Int>? {
        // `Int128` is wide enough to hold the product of any two 64-bit values, so the multiplication
        // cannot overflow even where the answer would not fit on its own: `Int.max` doubled is too
        // large for an `Int`, while two thirds of `Int.max` is not.
        let product = Int128(amount) * Int128(numerator.rawValue)

        let (wholePart, leftOver) = product.quotientAndRemainder(
            dividingBy: Int128(denominator.rawValue)
        )

        guard let whole = Int(exactly: wholePart) else {
            return nil
        }

        guard leftOver != 0 else {
            return .exact(whole)
        }

        // A remainder is always smaller than its divisor, which came from an `Int64`.
        return .inexact(whole, remainder: Ratio(Numerator(Int64(leftOver)), denominator))
    }
}

// MARK: - Reduction

private extension Ratio.Numerator {
    // Every integer is a valid numerator, so dividing can never produce an invalid one. Dividing by a
    // positive value also means `Int64.min / -1` — the one trapping integer division — cannot arise.
    func reduced(by divisor: Ratio.Denominator) -> Self {
        Self(rawValue / divisor.rawValue)
    }
}

private extension Ratio.Denominator {
    // The divisor divides this value exactly and never exceeds it, so the result is at least 1 and
    // remains a valid denominator.
    func reduced(by divisor: Ratio.Denominator) -> Self {
        Self(unchecked: rawValue / divisor.rawValue)
    }
}

// MARK: - CustomStringConvertible

extension Ratio: CustomStringConvertible {
    public var description: String {
        "\(numerator)/\(denominator)"
    }
}

// MARK: - Operands

public extension Ratio {
    /// The signed part of a ratio.
    ///
    /// Every integer is a valid numerator, so this cannot fail to be created — including from a
    /// literal, unlike ``Ratio/Denominator``.
    struct Numerator: Equatable, Hashable, Sendable, CustomStringConvertible {
        fileprivate let rawValue: Int64

        public var description: String {
            "\(rawValue)"
        }

        /// Creates a numerator.
        public init(_ value: Int64) {
            self.rawValue = value
        }
    }

    /// A positive integer, used as the denominator of a ratio.
    ///
    /// A ratio's sign is carried entirely by its numerator, so a denominator is never zero or
    /// negative. Those values cannot be constructed.
    struct Denominator: Equatable, Hashable, Sendable, CustomStringConvertible {
        fileprivate let rawValue: Int64

        public var description: String {
            "\(rawValue)"
        }

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
