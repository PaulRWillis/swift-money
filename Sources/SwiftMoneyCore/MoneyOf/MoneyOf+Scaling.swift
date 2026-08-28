public extension MoneyOf where C: CurrencyType {
    /// Returns this monetary amount split into `parts`, as evenly as possible.
    ///
    /// ```swift
    /// GBP(minorUnits: 100_00).split(into: 3)   // one part of £33.34, two of £33.33
    /// ```
    ///
    /// The parts always sum to the original amount, and no two differ by more than one minor unit.
    @inlinable
    func split(into parts: PartCount) -> Split<Self> {
        SwiftMoneyCore.split(minorUnits, into: parts)
            .map { Self(unchecked: $0, storage: .implied) }
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns this monetary amount split into `parts`, as evenly as possible.
    ///
    /// The parts always sum to the original amount, and no two differ by more than one minor unit.
    @inlinable
    func split(into parts: PartCount) -> Split<Self> {
        let currency = storage

        return SwiftMoneyCore.split(minorUnits, into: parts)
            .map { Self(unchecked: $0, storage: currency) }
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
        unrounded.applying(rate)
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
        unrounded.applying(rate)
    }
}
