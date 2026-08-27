/// How many of a currency's smallest units make one major unit.
///
/// `100` for pounds and euros, `1` for yen, `100_000_000` for bitcoin.
///
/// Not only powers of ten: the ouguiya divides into five khoums and the ariary into five
/// iraimbilanja. Every scale does have an exact decimal form, being `2 ^ a * 5 ^ b` and reaching no
/// further than eighteen decimal places, so one smallest unit can always be written as a decimal.
///
/// That forbids a scale keeping any other prime factor, such as pre-decimal sterling at 240 pence to
/// the pound, where one penny is 0.0041666… Every reader of a scale would otherwise need a second
/// form for the amounts it cannot write.
public struct UnitScale: Equatable, Hashable, Sendable {
    fileprivate let rawValue: Int64

    /// How many decimal places write one of the currency's smallest units exactly.
    ///
    /// `2` for pounds, `0` for yen, `3` for a scale of 8.
    package var decimalPlaces: Int {
        rawValue.decimalReduction.places
    }

    /// Creates a unit scale from a value that may not be valid.
    ///
    /// - Parameter value: The number of smallest units per major unit.
    /// - Returns: `nil` if `value` is below one, or has no exact decimal form.
    public init?(exactly value: Int64) {
        guard value >= 1,
              value.hasAnExactDecimalForm
        else {
            return nil
        }

        self.rawValue = value
    }
}

extension UnitScale: ExpressibleByIntegerLiteral {
    /// Creates a unit scale from an integer literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so an invalid value is a
    /// mistake in the source rather than bad input: it traps instead of failing gracefully. Use
    /// ``init(exactly:)`` for any value that is not a literal.
    ///
    /// ```swift
    /// let pence: UnitScale = 100        // fine
    /// let none: UnitScale = 0           // traps
    /// let shillings: UnitScale = 240    // traps: 240 keeps a factor of 3
    /// ```
    ///
    /// - Parameter value: The number of smallest units per major unit.
    /// - Precondition: `value` is at least one and divides a power of ten no finer than `10 ^ 18`.
    public init(integerLiteral value: Int64) {
        precondition(value >= 1, "A unit scale must be at least 1. Value: \(value)")
        precondition(
            value.hasAnExactDecimalForm,
            "A unit scale must divide a power of ten no finer than 10 ^ 18. Value: \(value)"
        )

        self.rawValue = value
    }
}

public extension Int64 {
    /// Creates an integer from a unit scale.
    init(_ scale: UnitScale) {
        self = scale.rawValue
    }
}

private extension Int64 {
    // The value with every factor of two and five divided out: how many decimal places one part in
    // `self` then needs, and whatever would not divide. A remainder above one means the reduction
    // did not finish.
    //
    // The caller must have established that the value is positive, `UInt64` having no room for a
    // negative one.
    var decimalReduction: (places: Int, remainder: UInt64) {
        var remaining = UInt64(self)
        var twos = 0
        var fives = 0

        while remaining.isMultiple(of: 2) {
            remaining /= 2
            twos += 1
        }

        while remaining.isMultiple(of: 5) {
            remaining /= 5
            fives += 1
        }

        return (Swift.max(twos, fives), remaining)
    }

    // Two and five are the only prime factors a decimal can absorb, so a value keeping any other
    // divides no power of ten: 240 keeps a 3, and one part in 240 is 0.0041666…
    //
    // Eighteen places is a chosen ceiling, not one the arithmetic forces. It is the largest power of
    // ten an `Int64` scale can itself be, and it is the bound the `Decimal` bridge already works to.
    // Overflow would not start until twenty places, where `powerOfTen` traps.
    var hasAnExactDecimalForm: Bool {
        let reduction = decimalReduction

        return reduction.remainder == 1 && reduction.places <= 18
    }
}
