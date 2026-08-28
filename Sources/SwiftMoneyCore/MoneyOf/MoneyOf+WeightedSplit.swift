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
    @inlinable
    func split(by weights: Weights) -> WeightedSplit<Self> {
        weightedSplit(over: weights, storage: .implied)
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
    @inlinable
    func split(by weights: Weights) -> WeightedSplit<Self> {
        weightedSplit(over: weights, storage: storage)
    }
}

extension MoneyOf where C: CurrencyRepresentation {
    // Pairs each weight with the minor-unit share the engine gave it, as an amount of this currency.
    // The engine returns one part per weight in order, so the two zip one-to-one.
    //
    // `@inlinable` so a concretely-typed amount specializes it at the call site rather than paying the
    // generic path, which for `MoneyOf<GBP>` measured far dearer than the runtime-currency `Money`.
    @inlinable
    func weightedSplit(over weights: Weights, storage: C.Storage) -> WeightedSplit<Self> {
        let parts = zip(weights.values, SwiftMoneyCore.split(minorUnits, by: weights)).map { weight, share in
            WeightedSplit<Self>.Part(
                weight: weight,
                amount: Self(unchecked: share, storage: storage)
            )
        }

        return WeightedSplit(parts: parts)
    }
}
