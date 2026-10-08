public extension MoneyOf where C: CurrencyType {
    /// Returns this monetary amount split into `parts`, as evenly as possible.
    ///
    /// The parts always sum to the original amount, and no two differ by more than one minor unit.
    ///
    /// ```swift
    /// GBP(minorUnits: 100_00).split(into: 3)   // one part of £33.34, two of £33.33
    /// ```
    ///
    /// - Parameter parts: The number of parts to split into.
    /// - Returns: The split.
    @inlinable
    func split(into parts: PartCount) -> Split<C> {
        Split(SwiftMoneyCore.split(minorUnits, into: parts), storage: .implied)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns this monetary amount split into `parts`, as evenly as possible.
    ///
    /// The parts always sum to the original amount, and no two differ by more than one minor unit.
    /// Every part carries this amount's currency.
    ///
    /// ```swift
    /// Money(minorUnits: 100_00, currency: .gbp).split(into: 3)   // one of £33.34, two of £33.33
    /// ```
    ///
    /// - Parameter parts: The number of parts to split into.
    /// - Returns: The split.
    @inlinable
    func split(into parts: PartCount) -> Split<C> {
        Split(SwiftMoneyCore.split(minorUnits, into: parts), storage: storage)
    }
}

public extension MoneyOf where C: CurrencyType {
    /// Returns this amount scaled by a rate, keeping the fraction of a unit for a single settling.
    ///
    /// A monetary amount is a whole number of the currency's smallest unit, but a rate need not divide
    /// exactly, so the result is ``Unrounded``. Settle it to a whole unit with ``Unrounded/rounded(_:)``,
    /// choosing the rule there. Applying rates in a chain then settles once at the end rather than at
    /// every step, which is what loses money.
    ///
    /// ```swift
    /// GBP(minorUnits: 10).applying("0.25").rounded(.toNearestOrEven)   // 2p, from 2.5p
    /// GBP(minorUnits: 10).applying("0.25").rounded(.up)                // 3p
    /// ```
    ///
    /// - Parameter rate: The rate to scale by.
    /// - Precondition: the scaled amount is representable.
    @inlinable func applying(_ rate: Rate) -> Unrounded {
        // The product is `minorUnits * rate`, which for a realistic rate is reached with one 64-by-128-bit
        // multiply rather than the widen-and-256-bit-divide the general path takes; an extreme rate falls
        // back to it.
        if let scaled = Fixed.scalingIfRepresentable(minorUnits, by: rate.value) {
            return Unrounded(scaled, storage: storage)
        }
        return unrounded.applying(rate)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns this amount scaled by a rate, keeping the fraction of a unit for a single settling.
    ///
    /// A rate need not divide exactly, so the result is ``Unrounded``. Settle it to a whole unit with
    /// ``Unrounded/rounded(_:)``, choosing the rule there. Applying rates in a chain then settles once at
    /// the end rather than at every step.
    ///
    /// - Parameter rate: The rate to scale by.
    /// - Precondition: the scaled amount is representable.
    @inlinable func applying(_ rate: Rate) -> Unrounded {
        if let scaled = Fixed.scalingIfRepresentable(minorUnits, by: rate.value) {
            return Unrounded(scaled, storage: storage)
        }
        return unrounded.applying(rate)
    }
}
