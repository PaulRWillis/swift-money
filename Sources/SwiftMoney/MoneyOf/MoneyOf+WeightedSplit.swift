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
    /// Weights that do not divide exactly leave minor units over. Each leftover unit goes to the
    /// part with the largest remainder, and the earliest part wins a tie, so every part sits as
    /// close as a whole unit can to its exact share.
    ///
    /// - Parameter weights: The weight of each part, in part order.
    @inlinable
    func split(by weights: Weights) -> [Self] {
        SwiftMoney.split(minorUnits, by: weights)
            .map { Self(unchecked: $0, storage: .implied) }
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns this monetary amount split into one part per weight.
    ///
    /// Part `i` comes from weight `i`, so the parts follow the weight order and their count
    /// equals the weight count. The parts always sum to the original amount.
    ///
    /// Weights that do not divide exactly leave minor units over. Each leftover unit goes to the
    /// part with the largest remainder, and the earliest part wins a tie, so every part sits as
    /// close as a whole unit can to its exact share.
    ///
    /// - Parameter weights: The weight of each part, in part order.
    @inlinable
    func split(by weights: Weights) -> [Self] {
        let currency = storage

        return SwiftMoney.split(minorUnits, by: weights)
            .map { Self(unchecked: $0, storage: currency) }
    }
}
