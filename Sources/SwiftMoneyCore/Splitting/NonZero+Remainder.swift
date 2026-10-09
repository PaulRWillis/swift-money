extension NonZero where Value == Money.MinorUnits {
    /// What a division by a number of parts leaves over: nothing, or some minor units.
    enum Remainder {
        /// The division was exact.
        case zero

        /// The division left minor units over, with those minor units.
        case nonZero(NonZero)

        /// Creates a remainder from the minor units a division left over.
        ///
        /// - Parameter value: The minor units left over, which may be zero.
        init(_ value: Value) {
            if let nonZero = NonZero(value) {
                self = .nonZero(nonZero)
            } else {
                self = .zero
            }
        }
    }

    /// Returns the quotient and remainder of this value divided by a number of parts.
    ///
    /// The remainder comes back as a ``Remainder`` rather than as minor units, so a caller has to
    /// decide what to do when it isn't zero rather than being able to ignore it.
    ///
    /// ```swift
    /// let amount = NonZero<Money.MinorUnits>(unchecked: 1_000_000)
    /// let (quotient, remainder) = amount.quotientAndRemainder(dividingBy: 933)
    /// // quotient == 1_071, remainder == .nonZero(757)
    /// ```
    ///
    /// - Parameter rhs: The number of parts to divide this value by.
    /// - Returns: The quotient, and the remainder as a ``Remainder``. A non-zero remainder has the
    ///   same sign as this value.
    func quotientAndRemainder(
        dividingBy rhs: PartCount
    ) -> (quotient: Money.MinorUnits, remainder: Remainder) {
        let (quotient, remainder) = rawValue.quotientAndRemainder(dividingBy: Int64(rhs))

        return (quotient, Remainder(remainder))
    }
}
