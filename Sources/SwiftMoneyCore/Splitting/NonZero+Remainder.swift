extension NonZero where Value == Money.MinorUnits {
    // What a division left over. Nested so that the enclosing type answers "a remainder of what",
    // which matters once more than one kind of remainder exists.
    enum Remainder {
        case zero
        case nonZero(NonZero)

        init(_ value: Value) {
            if let nonZero = NonZero(value) {
                self = .nonZero(nonZero)
            } else {
                self = .zero
            }
        }
    }

    /// Returns the quotient and remainder of this value divided by the given
    /// number of parts.
    ///
    /// The remainder comes back as a `Remainder` rather than as minor units, so
    /// a caller has to decide what to do when it is non-zero instead of being
    /// able to ignore it.
    ///
    ///     // an amount of 1,000,000, divided into 933 parts
    ///     let (quotient, remainder) = amount.quotientAndRemainder(dividingBy: 933)
    ///     // quotient  == 1071
    ///     // remainder == .nonZero(757)
    ///
    /// - Parameter dividingBy: The number of parts to divide this value by.
    /// - Returns: A tuple containing the quotient, and the remainder as a
    ///   `Remainder`. A non-zero remainder has the same sign as this value.
    func quotientAndRemainder(
        dividingBy rhs: PartCount
    ) -> (quotient: Money.MinorUnits, remainder: Remainder) {
        let (quotient, remainder) = rawValue.quotientAndRemainder(dividingBy: Int64(rhs))

        return (quotient, Remainder(remainder))
    }
}
