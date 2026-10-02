/// The result of splitting a monetary amount by weights.
///
/// One part per weight, in weight order, and the parts always sum to the original amount: a weighted
/// split does not lose or invent money. Each part carries the weight it came from alongside its share.
public struct WeightedSplit<C: CurrencyRepresentation>: Equatable {
    /// One part of a weighted split: a weight and the share it received.
    public struct Part: Equatable {
        /// The weight this part came from.
        public let weight: Weight

        /// The share this part received.
        public let amount: MoneyOf<C>

        /// Creates a part from its weight and the amount it receives.
        ///
        /// - Parameters:
        ///   - weight: The part's weight.
        ///   - amount: The amount the part receives.
        @usableFromInline
        init(
            weight: Weight,
            amount: MoneyOf<C>
        ) {
            // Not public: a caller could pair a weight with any share.
            self.weight = weight
            self.amount = amount
        }
    }

    /// The parts, one per weight, in weight order.
    public let parts: [Part]

    /// Creates a weighted split from its parts.
    ///
    /// - Parameter parts: The parts, one per weight, in weight order.
    @usableFromInline
    init(parts: [Part]) {
        // Not public: a caller could build parts that don't sum to any split amount.
        self.parts = parts
    }
}

public extension WeightedSplit {
    /// Each part's share, in weight order.
    ///
    /// `@inlinable` so it specializes for a concretely-typed amount at the call site rather than running
    /// the generic `map`, which for a typed `WeightedSplit` measured far dearer than the work it does.
    @inlinable
    var amounts: [MoneyOf<C>] {
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

extension WeightedSplit: Sendable {}

extension WeightedSplit.Part: Sendable {}
