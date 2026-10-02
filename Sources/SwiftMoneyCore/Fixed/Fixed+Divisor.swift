extension Fixed {
    /// A whole number of at least one, which a `Fixed` value can be divided by.
    @usableFromInline
    package struct Divisor: Equatable, Hashable, Sendable {
        /// The divisor, at least one.
        @usableFromInline let magnitude: UInt128

        /// Creates a divisor, returning `nil` if `value` is less than one.
        ///
        /// - Parameter value: The whole number to divide by.
        package init?(exactly value: Int128) {
            guard value > 0 else {
                return nil
            }

            self.magnitude = value.magnitude
        }

        /// Creates a divisor from a number of parts.
        @inlinable
        package init(_ parts: PartCount) {
            // A part count is at least one, so its bits read as unsigned are its value.
            self.magnitude = UInt128(UInt(bitPattern: Int(parts)))
        }

        /// Creates a divisor from the size of a non-zero amount of minor units, ignoring its sign.
        init(magnitudeOf amount: NonZeroInt64) {
            self.magnitude = UInt128(amount.rawValue.magnitude)
        }

        /// Creates a divisor from a unit scale: the smallest units in one major unit.
        package init(_ scale: UnitScale) {
            self.magnitude = UInt128(UInt64.powerOfTen(UInt64.DecimalExponent(scale)))
        }
    }
}

extension Fixed.Divisor: ExpressibleByIntegerLiteral {
    /// Creates a divisor from an integer literal.
    ///
    /// - Parameter value: The whole number to divide by.
    /// - Precondition: `value` must not be zero.
    @usableFromInline
    package init(integerLiteral value: UInt128) {
        precondition(value != 0, "A divisor must be at least one")

        self.magnitude = value
    }
}
