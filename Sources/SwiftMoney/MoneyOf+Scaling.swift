// MARK: - Splitting, which cannot fail for any currency

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

// MARK: - Fractional scaling, a currency fixed at compile time

public extension MoneyOf where C: CurrencyType {
    /// Returns this monetary amount scaled by a fraction.
    ///
    /// A monetary amount is always a whole number of the currency's smallest unit, so a fraction that
    /// does not divide exactly leaves part of a unit for the caller to resolve.
    ///
    /// ```swift
    /// GBP(minorUnits: 9_99).scaled(by: Ratio(1, 3))    // .exact(£3.33)
    /// GBP(minorUnits: 10_00).scaled(by: Ratio(1, 3))   // .inexact(£3.33, remainder: 1/3)
    /// ```
    ///
    /// - Parameter ratio: The fraction to scale by.
    /// - Precondition: The result is representable. Scaling past ``min`` or ``max`` traps.
    @inlinable
    func scaled(by ratio: Ratio) -> Scaled<Self> {
        guard let scaled = SwiftMoney.scaled(minorUnits, by: ratio) else {
            preconditionFailure("Scaling by \(ratio) is not representable")
        }

        // Switched here rather than through a shared `map`, which cost fifteen times as much: a
        // closure taken by a generic method, called from a generic type that is not inlinable, cannot
        // be specialized away.
        switch scaled {
        case let .exact(whole):
            return .exact(Self(unchecked: whole, storage: .implied))
        case let .inexact(whole, remainder):
            return .inexact(Self(unchecked: whole, storage: .implied), remainder: remainder)
        }
    }

    /// Returns this monetary amount scaled by a fraction and resolved to a whole unit.
    ///
    /// Use this where the caller already knows how a leftover part should be settled. Use
    /// ``scaled(by:)`` to find out whether there was one.
    ///
    /// ```swift
    /// GBP(minorUnits: 10).scaled(by: Ratio(1, 4), rounding: .toNearestOrEven)   // 2p, from 2.5p
    /// GBP(minorUnits: 10).scaled(by: Ratio(1, 4), rounding: .up)                // 3p
    /// ```
    ///
    /// - Parameters:
    ///   - ratio: The fraction to scale by.
    ///   - rule: How to resolve part of a unit left over.
    /// - Precondition: The result is representable, including where only the rounding step passes the
    ///   range.
    @inlinable
    func scaled(
        by ratio: Ratio,
        rounding rule: RoundingRule
    ) -> Self {
        guard
            let scaled = SwiftMoney.scaled(minorUnits, by: ratio),
            let rounded = scaled.rounded(rule)
        else {
            preconditionFailure("Scaling by \(ratio) is not representable")
        }

        return Self(unchecked: rounded, storage: .implied)
    }
}

// MARK: - Fractional scaling, a currency only known at runtime

public extension MoneyOf where C == AnyCurrency {
    /// Returns this monetary amount scaled by a fraction.
    ///
    /// - Parameter ratio: The fraction to scale by.
    /// - Precondition: The result is representable. Scaling past the largest or smallest amount traps.
    @inlinable
    func scaled(by ratio: Ratio) -> Scaled<Self> {
        guard let scaled = SwiftMoney.scaled(minorUnits, by: ratio) else {
            preconditionFailure("Scaling by \(ratio) is not representable")
        }

        switch scaled {
        case let .exact(whole):
            return .exact(Self(unchecked: whole, storage: storage))
        case let .inexact(whole, remainder):
            return .inexact(Self(unchecked: whole, storage: storage), remainder: remainder)
        }
    }

    /// Returns this monetary amount scaled by a fraction and resolved to a whole unit.
    ///
    /// - Parameters:
    ///   - ratio: The fraction to scale by.
    ///   - rule: How to resolve part of a unit left over.
    /// - Precondition: The result is representable, including where only the rounding step passes the
    ///   range.
    @inlinable
    func scaled(
        by ratio: Ratio,
        rounding rule: RoundingRule
    ) -> Self {
        guard
            let scaled = SwiftMoney.scaled(minorUnits, by: ratio),
            let rounded = scaled.rounded(rule)
        else {
            preconditionFailure("Scaling by \(ratio) is not representable")
        }

        return Self(unchecked: rounded, storage: storage)
    }
}
