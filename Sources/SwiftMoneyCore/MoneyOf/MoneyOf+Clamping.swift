// No clamp to `a..<b` or `..<b`: either can be empty (`a..<a`, or `..<` the smallest amount), so
// the clamp would be failable, and failable and throwing for runtime amounts.
public extension MoneyOf where C: CurrencyType {
    /// Returns this amount, moved to the nearer bound if it lies outside the given limits.
    ///
    /// ```swift
    /// GBP(minorUnits: 500_00).clamped(to: minimum...maximum)   // `maximum`, when £500 is above it
    /// ```
    ///
    /// - Parameter limits: The range to clamp to.
    @inlinable
    func clamped(to limits: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, limits.lowerBound), limits.upperBound)
    }

    /// Returns this amount, raised to the lower bound if it lies below it.
    ///
    /// - Parameter limits: The range to clamp to.
    @inlinable
    func clamped(to limits: PartialRangeFrom<Self>) -> Self {
        Swift.max(self, limits.lowerBound)
    }

    /// Returns this amount, lowered to the upper bound if it lies above it.
    ///
    /// - Parameter limits: The range to clamp to.
    @inlinable
    func clamped(to limits: PartialRangeThrough<Self>) -> Self {
        Swift.min(self, limits.upperBound)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns this amount, moved to the nearer bound if it lies outside the given limits.
    ///
    /// ```swift
    /// let deposit = try requested.clamped(to: minimum...maximum)
    /// ```
    ///
    /// - Parameter limits: The range to clamp to.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `limits` is in another currency, with
    ///   this amount's currency as `lhs`.
    @inlinable
    func clamped(to limits: ClosedMoneyRange) throws(MoneyError) -> Money {
        try AnyCurrency.requireMatch(storage, limits.currency)

        let lower = limits.lowerBound.minorUnits
        let upper = limits.upperBound.minorUnits

        return Money(unchecked: Swift.min(Swift.max(minorUnits, lower), upper), storage: storage)
    }

    /// Returns this amount, raised to the lower bound if it lies below it.
    ///
    /// - Parameter limits: The range to clamp to.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `limits` is in another currency, with
    ///   this amount's currency as `lhs`.
    @inlinable
    func clamped(to limits: PartialMoneyRangeFrom) throws(MoneyError) -> Money {
        try AnyCurrency.requireMatch(storage, limits.lowerBound.storage)

        return Money(unchecked: Swift.max(minorUnits, limits.lowerBound.minorUnits), storage: storage)
    }

    /// Returns this amount, lowered to the upper bound if it lies above it.
    ///
    /// - Parameter limits: The range to clamp to.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `limits` is in another currency, with
    ///   this amount's currency as `lhs`.
    @inlinable
    func clamped(to limits: PartialMoneyRangeThrough) throws(MoneyError) -> Money {
        try AnyCurrency.requireMatch(storage, limits.upperBound.storage)

        return Money(unchecked: Swift.min(minorUnits, limits.upperBound.minorUnits), storage: storage)
    }
}
