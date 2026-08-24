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

    /// Creates a ratio from two integers, reduced to lowest terms.
    ///
    /// ```swift
    /// Ratio(exactly: 7, over: 40)     // 7/40
    /// Ratio(exactly: 22, over: 200)   // 11/100
    /// Ratio(exactly: 1, over: 0)      // nil
    /// ```
    ///
    /// - Parameters:
    ///   - numerator: The signed part. Any value is valid.
    ///   - denominator: The part below the line.
    /// - Returns: `nil` if `denominator` is less than one.
    public init?(
        exactly numerator: Int64,
        over denominator: Int64
    ) {
        guard let denominator = Denominator(exactly: denominator) else {
            return nil
        }

        self.init(Numerator(numerator), denominator)
    }

    // No reduction: only for call sites that have already established the fraction is in lowest terms.
    // fileprivate for `proportion(_:of:)`, which divides both sides by their greatest common divisor
    // and so has already done the work this would repeat.
    fileprivate init(
        unchecked numerator: Numerator,
        _ denominator: Denominator
    ) {
        self.numerator = numerator
        self.denominator = denominator
    }

    // The result is a valid `Denominator` by construction: it divides the denominator, which is at
    // least 1, so the result is between 1 and the denominator inclusive.
    private static func greatestCommonDivisor(
        of first: Denominator,
        and second: Denominator
    ) -> Denominator {
        greatestCommonDivisor(of: Numerator(first.rawValue), and: second)
    }

    private static func greatestCommonDivisor(
        of numerator: Numerator,
        and denominator: Denominator
    ) -> Denominator {
        let divisor = SwiftMoney.greatestCommonDivisor(
            of: numerator.rawValue.magnitude,
            and: denominator.rawValue.magnitude
        )

        return Denominator(unchecked: Int64(divisor))
    }
}

// Euclid. On magnitudes because `abs(Int64.min)` overflows, while `Int64.min.magnitude` is 2^63 and
// fits in a `UInt64` comfortably.
//
// Zero only when both inputs are zero, which is the one case with no greatest common divisor. Callers
// holding a `Denominator` cannot reach it, that being at least one.
func greatestCommonDivisor(
    of first: UInt64,
    and second: UInt64
) -> UInt64 {
    var a = first
    var b = second

    // Larger first, as `swift-numerics` does: starting with the smaller spends a division arriving
    // where this already is. Worth it because every remainder starts that way, a leftover always
    // being below its divisor. Measured at roughly a tenth of the call.
    if a < b {
        swap(&a, &b)
    }

    while b != 0 {
        (a, b) = (b, a % b)
    }

    return a
}

// MARK: - Scaling

// The whole part of `amount` multiplied by `ratio`, truncated toward zero, together with whatever
// fraction is left over. The remainder carries the same sign as the whole part, so the two account for
// the exact product between them.
//
// `nil` when the whole part is not representable as an `Int64`.
//
// Here rather than beside ``Scaled`` — where its sibling `split(_:into:)` sits beside `Split` — because
// it needs this file's private storage, and needs to build a `FractionalRemainder`, whose initializer
// is deliberately reachable from nowhere else.
@usableFromInline
func scaled(
    _ amount: Int64,
    by ratio: Ratio
) -> Scaled<Int64>? {
    let sign = Sign(of: amount) * Sign(of: ratio.numerator.rawValue)

    let product = WideMagnitude(amount.magnitude, times: ratio.numerator.rawValue.magnitude)

    guard
        let division = product.quotientAndRemainder(dividingBy: ratio.denominator.rawValue.magnitude),
        let whole = Int64(magnitude: division.quotient, sign: sign)
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

// MARK: - Settling an exact count of units

// The whole number `exact` settles to under `rule`.
//
// Total, unlike `scaled(_:by:)`: a denominator of one leaves nothing to settle, and any larger
// denominator has already at least halved the numerator, so the step to the next unit always fits.
//
// Here rather than beside ``RoundingRule`` because it needs a `FractionalRemainder`, whose initializer
// is deliberately reachable from nowhere else.
@usableFromInline
func rounded(
    _ exact: Ratio,
    _ rule: RoundingRule
) -> Int64 {
    let nearZero = exact.numerator.rawValue / exact.denominator.rawValue
    let leftOver = exact.numerator.rawValue % exact.denominator.rawValue

    guard let remainder = exact.fractionalRemainder(leftOver.magnitude, sign: Sign(of: leftOver)) else {
        return nearZero
    }

    return nearZero + remainder.step(under: rule, from: nearZero)
}

// MARK: - Multiplication

internal extension Ratio {
    // This ratio multiplied by another, in lowest terms. `nil` when the product is not representable.
    //
    // Multiplies first and reduces the product, which spends one greatest common divisor rather than
    // two. Only if that overflows does it cancel across the two fractions instead, which succeeds
    // wherever the reduced product would have fitted all along.
    @usableFromInline
    func multiplied(by other: Ratio) -> Ratio? {
        let (numerator, numeratorOverflowed) = self.numerator.rawValue
            .multipliedReportingOverflow(by: other.numerator.rawValue)
        let (denominator, denominatorOverflowed) = self.denominator.rawValue
            .multipliedReportingOverflow(by: other.denominator.rawValue)

        guard !numeratorOverflowed, !denominatorOverflowed else {
            return cancelled(against: other)
        }

        return Ratio(Numerator(numerator), Denominator(unchecked: denominator))
    }
}

// MARK: - Addition

internal extension Ratio {
    // This ratio plus another, in lowest terms. `nil` when the sum is not representable.
    @usableFromInline
    func adding(_ other: Ratio) -> Ratio? {
        guard let restated = overCommonDenominator(other) else {
            return nil
        }

        let (total, overflowed) = restated.ours.addingReportingOverflow(restated.theirs)

        guard !overflowed else {
            return nil
        }

        return Ratio(Numerator(total), restated.denominator)
    }

    // This ratio minus another, in lowest terms. `nil` when the difference is not representable.
    @usableFromInline
    func subtracting(_ other: Ratio) -> Ratio? {
        guard let restated = overCommonDenominator(other) else {
            return nil
        }

        let (total, overflowed) = restated.ours.subtractingReportingOverflow(restated.theirs)

        guard !overflowed else {
            return nil
        }

        return Ratio(Numerator(total), restated.denominator)
    }
}

private extension Ratio {
    // Both numerators restated over the lowest common multiple of the two denominators. Two ratios that
    // already share a denominator keep it, where the product would square it.
    func overCommonDenominator(
        _ other: Ratio
    ) -> (ours: Int64, theirs: Int64, denominator: Denominator)? {
        let shared = Self.greatestCommonDivisor(of: denominator, and: other.denominator)
        let ourStep = other.denominator.reduced(by: shared)
        let theirStep = denominator.reduced(by: shared)

        let (common, commonOverflowed) = denominator.rawValue
            .multipliedReportingOverflow(by: ourStep.rawValue)
        let (ours, oursOverflowed) = numerator.rawValue
            .multipliedReportingOverflow(by: ourStep.rawValue)
        let (theirs, theirsOverflowed) = other.numerator.rawValue
            .multipliedReportingOverflow(by: theirStep.rawValue)

        guard !commonOverflowed, !oursOverflowed, !theirsOverflowed else {
            return nil
        }

        return (ours, theirs, Denominator(unchecked: common))
    }

    // Cancels each numerator against the other's denominator before multiplying, so common factors go
    // before anything grows. Both fractions are already in lowest terms, so the result is too.
    func cancelled(against other: Ratio) -> Ratio? {
        let ours = Self.greatestCommonDivisor(of: numerator, and: other.denominator)
        let theirs = Self.greatestCommonDivisor(of: other.numerator, and: denominator)

        let (numerator, numeratorOverflowed) = self.numerator.reduced(by: ours).rawValue
            .multipliedReportingOverflow(by: other.numerator.reduced(by: theirs).rawValue)
        let (denominator, denominatorOverflowed) = self.denominator.reduced(by: theirs).rawValue
            .multipliedReportingOverflow(by: other.denominator.reduced(by: ours).rawValue)

        guard !numeratorOverflowed, !denominatorOverflowed else {
            return nil
        }

        return Ratio(unchecked: Numerator(numerator), Denominator(unchecked: denominator))
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
    // How far `nearZero` moves once this leftover is resolved by `rule`: either nothing, or one whole
    // unit away from zero.
    //
    // The answer is one of the two whole numbers either side. Truncating already gave the one nearer
    // zero, so all the rule decides is whether to take the other.
    func step(
        under rule: RoundingRule,
        from nearZero: Int64
    ) -> Int64 {
        roundsAwayFromZero(under: rule, from: nearZero) ? signum : 0
    }

    // The whole number `nearZero` becomes once this leftover is resolved by `rule`.
    //
    // `nil` when that step is not representable: an amount that fits may not once it steps.
    func resolving(
        _ nearZero: Int64,
        _ rule: RoundingRule
    ) -> Int64? {
        let (rounded, didOverflow) = nearZero.addingReportingOverflow(step(under: rule, from: nearZero))

        return didOverflow ? nil : rounded
    }
}

private extension Ratio.FractionalRemainder {
    func roundsAwayFromZero(
        under rule: RoundingRule,
        from nearZero: Int64
    ) -> Bool {
        switch rule {
        case .towardZero:
            false
        case .awayFromZero:
            true
        case .down:
            isNegative
        case .up:
            !isNegative
        // The two nearest rules differ by one line: what to do with a tie.
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
        // `FloatingPointRoundingRule` belongs to the standard library and is not frozen, so a future
        // Swift can add a rule this build has never seen. Rounding money by a rule we cannot
        // interpret would have to guess, and a wrong guess is a wrong amount, so refuse instead.
        @unknown default:
            preconditionFailure("Unknown rounding rule: \(rule)")
        }
    }

    var isNegative: Bool {
        value.numerator.rawValue < 0
    }

    // `-1` when negative and `1` when positive. A remainder is never zero, so there is no third answer.
    var signum: Int64 {
        isNegative ? -1 : 1
    }

    // Where this remainder's magnitude sits against one half. Rounding to nearest needs all three
    // answers: a tie is the one case where a rule has to look at anything besides the remainder.
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

// The base a ratio string is written in.
private let decimalRadix: UInt64 = 10

public extension Ratio {
    /// Creates a ratio from a string that may not be valid.
    ///
    /// A fraction is converted exactly, with no rounding:
    ///
    /// ```swift
    /// Ratio(string: "1/3")     // one third, exactly
    /// Ratio(string: "-7/40")   // minus seven fortieths
    /// Ratio(string: "1/0")     // nil
    /// ```
    ///
    /// The whole string must be one fraction: ASCII digits, one optional leading `+` or `-`,
    /// and no whitespace. Each number as written must fit in 64 bits, even where the reduced
    /// value would fit.
    ///
    /// - Parameter string: The ratio, as a fraction.
    /// - Returns: `nil` unless the string is a ratio this type can hold exactly, written within
    ///   the limits above.
    init?(string: String) {
        guard let parsed = Self.parsed(string.utf8[...]) else {
            return nil
        }

        self = parsed
    }
}

private extension Ratio {
    typealias Bytes = String.UTF8View.SubSequence

    // The two magnitudes a parsed ratio is built from. Unsigned because a string carries its sign at
    // the front, where a ratio carries it on the numerator.
    struct Terms {
        let numerator: UInt64
        let denominator: UInt64

        // The same value with every common factor taken out. A denominator is at least one, so the
        // two magnitudes always have a greatest common divisor.
        var reduced: Self {
            let divisor = SwiftMoney.greatestCommonDivisor(of: numerator, and: denominator)

            return Self(numerator: numerator / divisor, denominator: denominator / divisor)
        }
    }

    // The ratio a run of bytes writes. `nil` unless the whole run is one ratio this type holds
    // exactly. Nothing is rounded: a string that does not convert exactly does not parse.
    static func parsed(_ bytes: Bytes) -> Ratio? {
        let (sign, body) = signed(bytes)

        return terms(in: body).flatMap { ratio(from: $0, sign: sign) }
    }

    // The sign a run of bytes leads with, and the body that follows it. A body with no sign of its
    // own is positive.
    static func signed(_ bytes: Bytes) -> (sign: Sign, body: Bytes) {
        switch bytes.first {
        case UInt8(ascii: "+"): (.positive, bytes.dropFirst())
        case UInt8(ascii: "-"): (.negative, bytes.dropFirst())
        default: (.positive, bytes)
        }
    }

    // The terms a body writes. `nil` unless the whole body is one fraction.
    static func terms(in body: Bytes) -> Terms? {
        guard let slash = body.firstIndex(of: UInt8(ascii: "/")) else {
            return nil
        }

        return fractionTerms(in: body, dividedAt: slash)
    }

    // The terms `digits "/" digits` writes. Digits only on both sides: a sign belongs at the front of
    // the string, and a denominator has no sign of its own.
    static func fractionTerms(
        in body: Bytes,
        dividedAt slash: Bytes.Index
    ) -> Terms? {
        guard
            let numerator = digits(in: body[..<slash]),
            let denominator = digits(in: body[body.index(after: slash)...]),
            denominator.value >= 1
        else {
            return nil
        }

        return Terms(numerator: numerator.value, denominator: denominator.value)
    }

    // The number a run of digits writes, and how many digits wrote it. `nil` unless the run holds at
    // least one byte, holds nothing but ASCII digits, and writes a number a `UInt64` holds.
    static func digits(in bytes: Bytes) -> (value: UInt64, count: Int)? {
        guard !bytes.isEmpty, let value = number(in: bytes) else {
            return nil
        }

        return (value, bytes.count)
    }

    // The number a run of digits writes, and zero where the run is empty. `nil` where a byte is
    // not an ASCII digit, or where the number grows past what a `UInt64` holds.
    static func number(in bytes: Bytes) -> UInt64? {
        bytes.reduce(UInt64?.some(0)) { number, byte in
            number?.appending(digit: byte)
        }
    }

    // The ratio `terms` writes, with `sign` applied. Reduces before it checks the range, as
    // `proportion(_:of:)` does: a fraction can be past what an `Int64` holds until it is reduced.
    static func ratio(
        from terms: Terms,
        sign: Sign
    ) -> Ratio? {
        let reduced = terms.reduced

        guard
            let numerator = Int64(magnitude: reduced.numerator, sign: sign),
            let whole = Int64(exactly: reduced.denominator),
            let denominator = Denominator(exactly: whole)
        else {
            return nil
        }

        return Ratio(unchecked: Numerator(numerator), denominator)
    }
}

private extension UInt64 {
    // This number with one more digit written after it. `nil` when the byte is not an ASCII digit, or
    // when the number has grown past what a `UInt64` holds.
    func appending(digit byte: UInt8) -> UInt64? {
        byte.asciiDigitValue.flatMap { digit in
            multiplied(by: decimalRadix)?.adding(UInt64(digit))
        }
    }

    // `nil` where `*` would trap.
    func multiplied(by other: UInt64) -> UInt64? {
        let (product, overflowed) = multipliedReportingOverflow(by: other)

        return overflowed ? nil : product
    }

    // `nil` where `+` would trap.
    func adding(_ other: UInt64) -> UInt64? {
        let (sum, overflowed) = addingReportingOverflow(other)

        return overflowed ? nil : sum
    }
}

// Deliberately byte level rather than `Character.isNumber`, which is true for the digits of many
// other scripts. A ratio string is ASCII, so no other script writes a number this parser reads.
private extension UInt8 {
    var asciiDigitValue: UInt8? {
        let zero = UInt8(ascii: "0")

        return (zero...UInt8(ascii: "9")).contains(self) ? self - zero : nil
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

// The fraction `part / whole`, reduced. `nil` when there is none: `whole` is zero and so has no parts,
// or the reduced fraction has no representable numerator.
//
// Here rather than beside ``MoneyOf`` because it builds a `Ratio` from its operand types, and reducing
// before the range check is what keeps `Int64.min` over an even whole in range.
@usableFromInline
func proportion(
    _ part: Int64,
    of whole: Int64
) -> Ratio? {
    let divisor = greatestCommonDivisor(of: part.magnitude, and: whole.magnitude)

    guard divisor != 0 else {
        return nil
    }

    guard
        let numerator = Int64(
            magnitude: part.magnitude / divisor,
            sign: Sign(of: part) * Sign(of: whole)
        ),
        let whole = Int64(exactly: whole.magnitude / divisor),
        let denominator = Ratio.Denominator(exactly: whole)
    else {
        return nil
    }

    return Ratio(unchecked: Ratio.Numerator(numerator), denominator)
}
