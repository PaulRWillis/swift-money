/// The result of splitting a monetary amount by weights.
///
/// One part per weight, in weight order, and the parts always sum to the original amount: a weighted
/// split does not lose or invent money. Each part carries the weight it came from alongside its share.
public struct WeightedDistribution<Amount: Equatable>: Equatable {
    /// One part of a weighted split: a weight and the share it received.
    public struct Part: Equatable {
        /// The weight this part came from.
        public let weight: Weight

        /// The share this part received.
        public let amount: Amount

        // Not public, so a distribution can only come from `split(by:)`, which is what guarantees the
        // invariants the type documents.
        init(
            weight: Weight,
            amount: Amount
        ) {
            self.weight = weight
            self.amount = amount
        }
    }

    /// The parts, one per weight, in weight order.
    public let parts: [Part]

    // Not public: see `Part.init`.
    init(parts: [Part]) {
        self.parts = parts
    }
}

public extension WeightedDistribution {
    /// Each part's share, in weight order.
    var amounts: [Amount] {
        parts.map(\.amount)
    }

    /// The weights, in order.
    var weights: [Weight] {
        parts.map(\.weight)
    }

    /// The number of parts, which equals the number of weights.
    var count: Int {
        parts.count
    }
}

extension WeightedDistribution: Sendable where Amount: Sendable {}

extension WeightedDistribution.Part: Sendable where Amount: Sendable {}
