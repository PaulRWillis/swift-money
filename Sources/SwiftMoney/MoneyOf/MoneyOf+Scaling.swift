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
        SwiftMoney.split(minorUnits, into: parts)
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

        return SwiftMoney.split(minorUnits, into: parts)
            .map { Self(unchecked: $0, storage: currency) }
    }
}

public extension MoneyOf where C: CurrencyType {
    /// Returns this monetary amount scaled by a rate.
    ///
    /// A monetary amount is always a whole number of the currency's smallest unit, so a rate that does
    /// not divide exactly leaves part of a unit for the caller to resolve.
    ///
    /// ```swift
    /// GBP(minorUnits: 9_99).scaled(by: "1/3")    // .exact(£3.33)
    /// GBP(minorUnits: 10_00).scaled(by: "0.2")   // .exact(£2.00)
    /// GBP(minorUnits: 10).scaled(by: "0.25")     // .inexact(2p, remainder: half a unit)
    /// ```
    ///
    /// - Parameter rate: The rate to scale by.
    /// - Precondition: The result is representable. Scaling past ``min`` or ``max`` traps.
    func scaled(by rate: Rate) -> Scaled<Self> {
        guard let scaled = SwiftMoney.scaled(minorUnits, by: rate) else {
            preconditionFailure("Scaling by a rate is not representable")  // coverage:ignore — exit-test trap
        }

        switch scaled {
        case let .exact(whole):
            return .exact(Self(unchecked: whole, storage: .implied))
        case let .inexact(whole, remainder):
            return .inexact(Self(unchecked: whole, storage: .implied), remainder: remainder)
        }
    }

    /// Returns this monetary amount scaled by a rate and resolved to a whole unit.
    ///
    /// Use this where the caller already knows how a leftover part should be settled. Use
    /// ``scaled(by:)`` to find out whether there was one.
    ///
    /// ```swift
    /// GBP(minorUnits: 10).scaled(by: "0.25", rounding: .toNearestOrEven)   // 2p, from 2.5p
    /// GBP(minorUnits: 10).scaled(by: "0.25", rounding: .up)                // 3p
    /// ```
    ///
    /// - Parameters:
    ///   - rate: The rate to scale by.
    ///   - rule: How to resolve part of a unit left over.
    /// - Precondition: The result is representable, including where only the rounding step passes the
    ///   range.
    func scaled(
        by rate: Rate,
        rounding rule: RoundingRule
    ) -> Self {
        guard
            let scaled = SwiftMoney.scaled(minorUnits, by: rate),
            let rounded = scaled.rounded(rule)
        else {
            preconditionFailure("Scaling by a rate is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(unchecked: rounded, storage: .implied)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns this monetary amount scaled by a rate.
    ///
    /// - Parameter rate: The rate to scale by.
    /// - Precondition: The result is representable. Scaling past the largest or smallest amount traps.
    func scaled(by rate: Rate) -> Scaled<Self> {
        guard let scaled = SwiftMoney.scaled(minorUnits, by: rate) else {
            preconditionFailure("Scaling by a rate is not representable")  // coverage:ignore — exit-test trap
        }

        switch scaled {
        case let .exact(whole):
            return .exact(Self(unchecked: whole, storage: storage))
        case let .inexact(whole, remainder):
            return .inexact(Self(unchecked: whole, storage: storage), remainder: remainder)
        }
    }

    /// Returns this monetary amount scaled by a rate and resolved to a whole unit.
    ///
    /// - Parameters:
    ///   - rate: The rate to scale by.
    ///   - rule: How to resolve part of a unit left over.
    /// - Precondition: The result is representable, including where only the rounding step passes the
    ///   range.
    func scaled(
        by rate: Rate,
        rounding rule: RoundingRule
    ) -> Self {
        guard
            let scaled = SwiftMoney.scaled(minorUnits, by: rate),
            let rounded = scaled.rounded(rule)
        else {
            preconditionFailure("Scaling by a rate is not representable")  // coverage:ignore — exit-test trap
        }

        return Self(unchecked: rounded, storage: storage)
    }
}
