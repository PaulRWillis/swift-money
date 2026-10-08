public extension MoneyOf where C: CurrencyType {
    /// Returns this monetary amount split into one part per weight.
    ///
    /// Part `i` comes from weight `i`, and the parts sum to this amount. Leftover minor units go to
    /// the largest remainders, earliest first, so each part is within one unit of its exact share.
    ///
    /// ```swift
    /// GBP(minorUnits: 100).split(by: [60, 30, 10]).amounts   // [£0.60, £0.30, £0.10]
    /// ```
    ///
    /// - Parameter weights: The weight of each part, in part order.
    /// - Returns: The weighted split.
    /// - Complexity: O(*n* log *n*), where *n* is the number of weights.
    @inlinable
    func split(by weights: Weights) -> WeightedSplit<C> {
        weightedSplit(over: weights, storage: .implied)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Returns this monetary amount split into one part per weight.
    ///
    /// Part `i` comes from weight `i`, and the parts sum to this amount. Leftover minor units go to
    /// the largest remainders, earliest first, so each part is within one unit of its exact share.
    ///
    /// ```swift
    /// let gbp = Money(minorUnits: 100, currency: .gbp)
    /// gbp.split(by: [60, 30, 10]).amounts   // [£0.60, £0.30, £0.10]
    /// ```
    ///
    /// - Parameter weights: The weight of each part, in part order.
    /// - Returns: The weighted split.
    /// - Complexity: O(*n* log *n*), where *n* is the number of weights.
    @inlinable
    func split(by weights: Weights) -> WeightedSplit<C> {
        weightedSplit(over: weights, storage: storage)
    }
}

extension MoneyOf where C: CurrencyRepresentation {
    /// Returns this monetary amount split into one part per weight, in the given currency storage.
    ///
    /// - Parameters:
    ///   - weights: The weight of each part, in part order.
    ///   - storage: The currency storage each part's amount is built from.
    /// - Returns: The weighted split, with one part per weight.
    /// - Complexity: O(*n* log *n*), where *n* is the number of weights.
    @inlinable
    func weightedSplit(over weights: Weights, storage: C.Storage) -> WeightedSplit<C> {
        let shares = SwiftMoneyCore.split(minorUnits, by: weights)
        let parts = zip(weights.values, shares).map { weight, share in
            WeightedSplit<C>.Part(
                weight: weight,
                amount: Self(unchecked: share, storage: storage)
            )
        }

        return WeightedSplit(parts: parts)
    }
}
