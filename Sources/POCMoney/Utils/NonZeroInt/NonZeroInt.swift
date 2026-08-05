struct NonZeroInt: Equatable, Hashable, Sendable {
    let rawValue: Int

    init?(_ value: Int) {
        guard value != 0 else {
            return nil
        }

        self.rawValue = value
    }

    /// Returns `-1` if this value is negative and `1` if it's positive.
    var signum: Int {
        rawValue < 0 ? -1 : 1
    }
}

extension NonZeroInt {
    /// Returns the quotient and remainder of this value divided by the given
    /// number of parts.
    ///
    /// The remainder comes back as a `Remainder` rather than an `Int`, so a
    /// caller has to decide what to do when it is non-zero instead of being
    /// able to ignore it.
    ///
    ///     let x = NonZeroInt(1_000_000)!
    ///     let (q, r) = x.quotientAndRemainder(dividingBy: 933)
    ///     // q == 1071
    ///     // r == .nonZero(757)
    ///
    /// - Parameter dividingBy: The number of parts to divide this value by.
    /// - Returns: A tuple containing the quotient, and the remainder as a
    ///   `Remainder`. A non-zero remainder has the same sign as this value.
    func quotientAndRemainder(
        dividingBy rhs: PartCount
    ) -> (quotient: Int, remainder: Remainder) {
        let (quotient, remainder) = rawValue.quotientAndRemainder(dividingBy: Int(rhs))

        return (quotient, Remainder(remainder))
    }
}
