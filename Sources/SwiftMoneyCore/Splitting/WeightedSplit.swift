/// The result of splitting a monetary amount by weights.
///
/// One part per weight, in weight order, and the parts always sum to the original amount: a weighted
/// split does not lose or invent money. Each part carries the weight it came from alongside its share.
public struct WeightedSplit<Amount: Equatable>: Equatable {
    /// One part of a weighted split: a weight and the share it received.
    public struct Part: Equatable {
        /// The weight this part came from.
        public let weight: Weight

        /// The share this part received.
        public let amount: Amount

        // Not public, so a weighted split can only come from `split(by:)`, which is what guarantees
        // the invariants the type documents.
        @usableFromInline
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
    @usableFromInline
    init(parts: [Part]) {
        self.parts = parts
    }
}

public extension WeightedSplit {
    /// Each part's share, in weight order.
    ///
    /// `@inlinable` so it specializes for a concretely-typed amount at the call site rather than running
    /// the generic `map`, which for a typed `WeightedSplit` measured far dearer than the work it does.
    @inlinable
    var amounts: [Amount] {
        parts.map(\.amount)
    }

    /// The weights, in order.
    @inlinable
    var weights: [Weight] {
        parts.map(\.weight)
    }

    /// The number of parts, which equals the number of weights.
    @inlinable
    var count: Int {
        parts.count
    }
}

extension WeightedSplit: Sendable where Amount: Sendable {}

extension WeightedSplit.Part: Sendable where Amount: Sendable {}
