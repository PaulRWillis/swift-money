// MARK: - Distribution

extension Money {
    /// Distributes this value into `n` equal-or-near-equal parts.
    ///
    /// Uses integer division in minor units:
    /// - `quotient` = `minorUnits / n` (truncating towards zero)
    /// - If the remainder is zero, returns `.exact(share: quotient, count: n)`.
    /// - Otherwise returns `.uneven` where `larger = quotient + sign`,
    ///   `largerCount = |minorUnits % n|`, `smaller = quotient`, and
    ///   `sign` is `+1` for non-negative amounts or `-1` for negative amounts.
    ///
    /// The sum invariant `distribution.sum == self` always holds.
    ///
    /// - Parameter n: Number of parts; must be ≥ 1.
    /// - Precondition: `self` must not be NaN.
    public func distributed(into n: DistributionParts) -> Distribution<Currency> {
        precondition(!isNaN, "Cannot distribute NaN")

        let amount = _storage
        let parts = Storage(n.intValue)
        let quotient  = amount / parts
        let remainder = amount % parts          // same sign as amount (Swift semantics)
        let remainderCount = Int(abs(remainder))
        let smaller = Money(_unchecked: quotient)

        guard remainderCount > 0 else {
            return .exact(share: smaller, count: n.intValue)
        }

        let sign: Storage = amount >= 0 ? 1 : -1
        return .uneven(
            larger: Money(_unchecked: quotient + sign),
            largerCount: remainderCount,
            smaller: smaller,
            smallerCount: n.intValue - remainderCount
        )
    }
}
