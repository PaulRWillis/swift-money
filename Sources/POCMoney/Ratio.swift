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
    // fileprivate rather than private so that `scaled(_:by:)`, a free function further down this file,
    // can read them. Both stay invisible outside it.
    fileprivate let numerator: Numerator
    fileprivate let denominator: Denominator

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

// MARK: - Scaling

// The whole part of `amount` multiplied by `ratio`, truncated toward zero, together with whatever
// fraction is left over. The remainder carries the same sign as the whole part, so the two account for
// the exact product between them.
//
// `nil` when the whole part is not representable as an `Int`.
//
// Here rather than beside ``Scaled`` — where its sibling `split(_:into:)` sits beside `Split` — because
// it needs this file's private storage, and needs to build a `FractionalRemainder`, whose initializer
// is deliberately reachable from nowhere else.
func scaled(
    _ amount: Int,
    by ratio: Ratio
) -> Scaled<Int>? {
    let sign = Sign(of: amount) * Sign(of: ratio.numerator.rawValue)

    // Widened before taking the magnitude, because `Int` is narrower than an `Int64` on arm64_32.
    let product = WideMagnitude(Int64(amount).magnitude, times: ratio.numerator.rawValue.magnitude)

    guard
        let division = product.quotientAndRemainder(dividingBy: ratio.denominator.rawValue.magnitude),
        let whole = Int(magnitude: division.quotient, sign: sign)
    else {
        return nil
    }

    guard let remainder = ratio.fractionalRemainder(division.remainder, sign: sign) else {
        return .exact(whole)
    }

    return .inexact(whole, remainder: remainder)
}

private extension Ratio {
    // What a division by this ratio's denominator left over, as a fraction of one unit. `nil` when the
    // division came out exact.
    func fractionalRemainder(
        _ leftOver: UInt64,
        sign: Sign
    ) -> FractionalRemainder? {
        guard leftOver != 0 else {
            return nil
        }

        // A remainder is always smaller than its divisor, which came from an `Int64`, so it fits and
        // negating it cannot overflow. Non-zero by the guard above — together, the invariant the type
        // promises.
        let magnitude = Int64(leftOver)
        let signed = sign == .negative ? -magnitude : magnitude

        return FractionalRemainder(unchecked: Ratio(Numerator(signed), denominator))
    }
}

// MARK: - Fractional Remainder

public extension Ratio {
    /// The part of one unit left over by a division.
    ///
    /// Never zero, and always less than one whole. There is no way to create one — a remainder comes
    /// only from a division that left something over, so a result cannot claim a remainder it does not
    /// have.
    struct FractionalRemainder: Equatable, Hashable, Sendable, CustomStringConvertible {
        fileprivate let value: Ratio

        public var description: String {
            value.description
        }

        // fileprivate so a remainder can only come from a division in this file. That is what makes
        // the guarantee above true, since nothing here validates it.
        fileprivate init(unchecked value: Ratio) {
            self.value = value
        }
    }

    /// Creates a ratio from the part of a unit left over by a division.
    init(_ remainder: FractionalRemainder) {
        self = remainder.value
    }
}

// MARK: - Resolving a remainder

internal extension Ratio.FractionalRemainder {
    // The whole number `nearZero` becomes once this leftover is resolved by `mode`.
    //
    // The answer is one of the two whole numbers either side. Truncating already gave the one nearer
    // zero, so all the mode decides is whether to take the other.
    //
    // `nil` when that step is not representable: an amount that fits may not once it steps.
    func resolving(
        _ nearZero: Int,
        _ mode: RoundingMode
    ) -> Int? {
        guard roundsAwayFromZero(under: mode, from: nearZero) else {
            return nearZero
        }

        let (rounded, didOverflow) = nearZero.addingReportingOverflow(signum)

        return didOverflow ? nil : rounded
    }
}

private extension Ratio.FractionalRemainder {
    func roundsAwayFromZero(
        under mode: RoundingMode,
        from nearZero: Int
    ) -> Bool {
        switch mode {
        case .towardZero:
            false
        case .awayFromZero:
            true
        case .floor:
            isNegative
        case .ceiling:
            !isNegative
        // The two nearest modes differ by one line: what to do with a tie.
        case .toNearestOrAwayFromZero:
            switch comparedToHalf {
            case .lessThanHalf: false
            case .equalToHalf: true
            case .moreThanHalf: true
            }
        case .toNearestOrEven:
            switch comparedToHalf {
            case .lessThanHalf: false
            case .equalToHalf: !nearZero.isMultiple(of: 2)
            case .moreThanHalf: true
            }
        }
    }

    var isNegative: Bool {
        value.numerator.rawValue < 0
    }

    // `-1` when negative and `1` when positive. A remainder is never zero, so there is no third answer.
    var signum: Int {
        isNegative ? -1 : 1
    }

    // Where this remainder's magnitude sits against one half. Rounding to nearest needs all three
    // answers: a tie is the one case where a mode has to look at anything besides the remainder.
    enum ComparedToHalf {
        case lessThanHalf
        case equalToHalf
        case moreThanHalf
    }

    var comparedToHalf: ComparedToHalf {
        // Comparing what was left over with the distance to the next whole unit answers the same
        // question as comparing it with a half, and is the same comparison Foundation's `Decimal` makes.
        // Nothing can overflow, since a remainder is always smaller than its denominator.
        let leftOver = value.numerator.rawValue.magnitude
        let toNextWholeUnit = value.denominator.rawValue.magnitude - leftOver

        if leftOver < toNextWholeUnit {
            return .lessThanHalf
        }

        return leftOver == toNextWholeUnit ? .equalToHalf : .moreThanHalf
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
