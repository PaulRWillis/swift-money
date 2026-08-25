public extension MoneyOf where C: CurrencyType {
    /// Returns this monetary amount split into one part per weight.
    ///
    /// ```swift
    /// GBP(minorUnits: 100).split(by: [60, 30, 10])   // [£0.60, £0.30, £0.10]
    /// ```
    ///
    /// Part `i` comes from weight `i`, so the parts follow the weight order and their count
    /// equals the weight count. The parts always sum to the original amount.
    ///
    /// - Parameter weights: The weight of each part, in part order.
    @inlinable
    func split(by weights: Weights) -> [Self] {
        SwiftMoney.split(minorUnits, by: weights)
            .map { Self(unchecked: $0, storage: .implied) }
    }
}
