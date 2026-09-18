/// The part of an amount a plural rule looks at, named by the letter CLDR's rule text uses for it.
package enum PluralOperand: String, Equatable, Sendable {
    /// The amount's absolute value, fraction included.
    case absoluteValue = "n"

    /// The whole part of the absolute value.
    case integerPart = "i"

    /// How many fraction digits are shown, trailing zeros included.
    case fractionDigitCount = "v"

    /// How many fraction digits are shown once trailing zeros are dropped.
    case significantFractionDigitCount = "w"

    /// The fraction digits shown, as a whole number, trailing zeros included.
    case fractionDigits = "f"

    /// The fraction digits shown as a whole number, once trailing zeros are dropped.
    case significantFractionDigits = "t"

    /// The power of ten the amount is written against in compact notation, as in `1c6` for a million.
    case compactExponent = "e"
}

extension PluralOperand {
    /// What an operand comes to for one amount.
    package enum Value: Equatable, Sendable {
        /// A whole number.
        case whole(UInt64)

        /// A value that carries a fraction.
        case fractional
    }
}

extension PluralOperand.Value {
    /// Returns the remainder of dividing this value by `modulus`.
    package func reduced(modulo modulus: PluralModulus) -> Self {
        switch self {
        case .whole(let whole):
            .whole(modulus.remainder(of: whole))
        case .fractional:
            .fractional   // a fraction survives the division, and matches no range either way
        }
    }

    /// Returns whether this value falls in any of `ranges`.
    ///
    /// CLDR's ranges hold whole numbers only, so a value carrying a fraction is in none of them.
    package func matches(anyOf ranges: NonEmpty<PluralRange>) -> Bool {
        guard case .whole(let whole) = self else {
            return false
        }

        return ranges.contains { $0.contains(whole) }
    }
}
