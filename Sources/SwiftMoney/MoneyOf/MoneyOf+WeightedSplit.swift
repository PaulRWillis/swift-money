public extension MoneyOf where C: CurrencyType {
    /// Returns this monetary amount split into one part per weight.
    ///
    /// ```swift
    /// GBP(minorUnits: 100).split(by: [60, 30, 10]).amounts   // [£0.60, £0.30, £0.10]
    /// ```
    ///
    /// Part `i` comes from weight `i`, so the parts follow the weight order and their count
    /// equals the weight count. The parts always sum to the original amount.
    ///
    /// Weights that do not divide exactly leave minor units over. Each leftover unit goes to the
    /// part with the largest remainder, and the earliest part wins a tie, so no part differs from
    /// its exact share by a whole minor unit or more.
    ///
    /// - Parameter weights: The weight of each part, in part order.
    func split(by weights: Weights) -> WeightedDistribution<Self> {
        distribution(
            of: SwiftMoney.split(minorUnits, by: weights),
            over: weights,
            storage: .implied
        )
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns this monetary amount split into one part per weight.
    ///
    /// Part `i` comes from weight `i`, so the parts follow the weight order and their count
    /// equals the weight count. The parts always sum to the original amount.
    ///
    /// Weights that do not divide exactly leave minor units over. Each leftover unit goes to the
    /// part with the largest remainder, and the earliest part wins a tie, so no part differs from
    /// its exact share by a whole minor unit or more.
    ///
    /// - Parameter weights: The weight of each part, in part order.
    func split(by weights: Weights) -> WeightedDistribution<Self> {
        distribution(
            of: SwiftMoney.split(minorUnits, by: weights),
            over: weights,
            storage: storage
        )
    }
}

private extension MoneyOf where C: CurrencyRepresentation {
    // Pairs each weight with the minor-unit share the engine gave it, as an amount of this currency.
    // The engine returns one part per weight in order, so the two zip one-to-one.
    func distribution(
        of shares: [Int64],
        over weights: Weights,
        storage: C.Storage
    ) -> WeightedDistribution<Self> {
        let parts = zip(weights.values, shares).map { weight, share in
            WeightedDistribution<Self>.Part(
                weight: weight,
                amount: Self(unchecked: share, storage: storage)
            )
        }

        return WeightedDistribution(parts: parts)
    }
}
