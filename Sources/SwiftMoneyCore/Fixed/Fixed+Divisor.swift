extension Fixed {
    /// A whole number of at least one, which a `Fixed` value can be divided by.
    @usableFromInline
    package struct Divisor: Equatable, Hashable, Sendable {
        /// The divisor, at least one.
        @usableFromInline let magnitude: UInt128Words

        /// Creates a divisor, returning `nil` if `value` is less than one.
        ///
        /// - Parameter value: The whole number to divide by.
        package init?(exactly value: Int128Words) {
            guard value > 0 else {
                return nil
            }

            self.magnitude = value.magnitude
        }

        /// Creates a divisor from a number of parts.
        @inlinable
        package init(_ parts: PartCount) {
            // A part count is at least one, so its bits read as unsigned are its value.
            self.magnitude = UInt128Words(UInt64(UInt(bitPattern: Int(parts))))
        }

        /// Creates a divisor from the size of a non-zero amount of minor units, ignoring its sign.
        ///
        /// - Parameter amount: The minor units whose size to divide by.
        init(magnitudeOf amount: NonZero<Money.MinorUnits>) {
            self.magnitude = UInt128Words(amount.rawValue.magnitude)
        }

        /// Creates a divisor from a unit scale: the smallest units in one major unit.
        package init(_ scale: UnitScale) {
            self.magnitude = UInt128Words(UInt64.powerOfTen(UInt64.DecimalExponent(scale)))
        }
    }
}

extension Fixed.Divisor: ExpressibleByIntegerLiteral {
    /// Creates a divisor from an integer literal.
    ///
    /// ```swift
    /// let daysInAYear: Fixed.Divisor = 365
    /// ```
    ///
    /// - Parameter value: The whole number to divide by.
    /// - Precondition: `value` must be in `1...2^128 - 1`.
    @usableFromInline
    package init(integerLiteral value: StaticBigInt) {
        precondition(value.signum() > 0, "A divisor must be at least one")

        self.magnitude = UInt128Words(integerLiteral: value)
    }
}
