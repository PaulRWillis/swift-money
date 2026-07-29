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

extension NonZeroInt: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        precondition(value != 0, "Value must not be 0")

        self.rawValue = value
    }
}

extension NonZeroInt: Comparable {
    static func < (lhs: NonZeroInt, rhs: NonZeroInt) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension NonZeroInt {
    /// Returns the quotient and remainder of this value divided by the given
    /// value.
    ///
    /// Use this method to calculate the quotient and remainder of a division at
    /// the same time.
    ///
    ///     let x: NonZeroInt = 1_000_000
    ///     let (q, r) = x.quotientAndRemainder(dividingBy: 933)
    ///     // q == 1071
    ///     // r == 757
    ///
    /// - Parameter rhs: The value to divide this value by.
    /// - Returns: A tuple containing the quotient and remainder of this value
    ///   divided by `rhs`. The remainder has the same sign as `lhs`.
    func quotientAndRemainder(
        dividingBy rhs: NonZeroInt
    ) -> (quotient: Int, remainder: Int) {
        rawValue.quotientAndRemainder(dividingBy: rhs.rawValue)
    }

    /// Returns the quotient and remainder of this value divided by the given
    /// value.
    ///
    /// Use this method to calculate the quotient and remainder of a division at
    /// the same time.
    ///
    ///     let x: NonZeroInt = 1_000_000
    ///     let (q, r) = x.quotientAndRemainder(dividingBy: 933)
    ///     // q == 1071
    ///     // r == 757
    ///
    /// - Parameter rhs: The value to divide this value by.
    /// - Returns: A tuple containing the quotient and remainder of this value
    ///   divided by `rhs`. The remainder has the same sign as `lhs`.
    func quotientAndRemainder(
        dividingBy rhs: PartCount
    ) -> (quotient: Int, remainder: Remainder) {
        let (quotient, remainder) = rawValue.quotientAndRemainder(dividingBy: Int(rhs))

        return (quotient, Remainder(remainder))
    }
}

extension Int {
    init(_ nonZeroInt: NonZeroInt) {
        self = nonZeroInt.rawValue
    }
}

enum Remainder {
    case zero
    case nonZero(NonZeroInt)

    init(_ value: Int) {
        if let nonZero = NonZeroInt(value) {
            self = .nonZero(nonZero)
        } else {
            self = .zero
        }
    }
}
