/// The result of splitting a monetary amount into a number of parts.
///
/// The parts always sum to the original amount, and no two parts differ by more than one minor
/// unit — a split does not lose or invent money.
public enum Split<Amount: Equatable> {
    /// Every part receives the same amount.
    case even(Group)

    /// Some parts receive one more minor unit than the others.
    ///
    /// `larger` and `smaller` compare by *magnitude*, not numerically: splitting a refund of
    /// `-10` into three gives `larger` of one part at `-4` and `smaller` of two parts at `-3`.
    case uneven(
        larger: Group,
        smaller: Group
    )
}

extension Split {
    /// A number of parts that each receive the same amount.
    public struct Group: Equatable {
        /// The number of parts in this group, which for an uneven split is fewer than the number
        /// of parts the amount was split into.
        public let count: PartCount

        /// The amount each part in this group receives, not the group's total.
        public let amount: Amount

        // Not public, so a `Split` can only come from `split(_:into:)`, which is what guarantees
        // the invariants that the type documents.
        @inlinable
        init(
            count: PartCount,
            amount: Amount
        ) {
            self.count = count
            self.amount = amount
        }
    }
}

extension Split {
    /// The number of parts the amount was split into.
    public var count: PartCount {
        switch self {
        case let .even(group):
            return group.count
        case let .uneven(larger, smaller):
            return PartCount(unchecked: Int(larger.count) + Int(smaller.count))
        }
    }

    /// Every part's amount, one element per part, larger amounts first.
    ///
    /// A `Split` stores each group of equal parts as a single ``Split/Group``, so splitting into a
    /// million parts holds two counts and two amounts. Iterating expands that on demand and
    /// allocates nothing.
    ///
    /// ```swift
    /// let split = GBP(100_00).split(into: 3)
    /// for amount in split.amounts { … }        // £33.34, £33.33, £33.33
    /// let all = Array(split.amounts)           // materialises, one element per part
    /// ```
    ///
    /// - Note: This is a `Sequence` rather than a `Collection`, deliberately. `Collection` would
    ///   require `count` to be an `Int`, which cannot coexist with ``Split/count`` returning
    ///   ``PartCount``; it would require a subscript whose valid range depends on the instance and
    ///   so cannot be expressed in any index type, leaving a trap as the only option; and it would
    ///   make `first`, `last`, `max()` and `min()` optional for a value that always has at least one
    ///   part. Implementing `underestimatedCount` also makes `Array(split.amounts)` roughly twice as
    ///   fast as the equivalent `RandomAccessCollection`, because capacity is reserved exactly.
    ///
    /// - Note: Iterating does not consume the sequence — it can be traversed repeatedly — though
    ///   `Sequence` does not promise that to generic code.
    public var amounts: some Sequence<Amount> {
        Amounts(self)
    }

    fileprivate struct Amounts: Sequence {
        private let split: Split

        fileprivate init(_ split: Split) {
            self.split = split
        }

        var underestimatedCount: Int {
            Int(split.count)
        }

        func makeIterator() -> Iterator {
            Iterator(split)
        }

        // Everything about the split is settled once, in the initializer. Reading it out of the enum
        // per element meant recomputing `count` — itself a switch, two conversions and an addition —
        // on every call to `next()`, for a value that cannot change while iterating.
        struct Iterator: IteratorProtocol {
            private let larger: Amount
            private let smaller: Amount
            private let largerCount: Int
            private let count: Int
            private var position = 0

            fileprivate init(_ split: Split) {
                switch split {
                case let .even(group):
                    larger = group.amount
                    smaller = group.amount
                    largerCount = Int(group.count)
                    count = largerCount
                case let .uneven(largerGroup, smallerGroup):
                    larger = largerGroup.amount
                    smaller = smallerGroup.amount
                    largerCount = Int(largerGroup.count)
                    count = largerCount + Int(smallerGroup.count)
                }
            }

            mutating func next() -> Amount? {
                guard position < count else {
                    return nil
                }

                defer { position += 1 }

                return position < largerCount ? larger : smaller
            }
        }
    }
}

// MARK: - Equatable

extension Split: Equatable {}

// MARK: - Sendable

extension Split: Sendable where Amount: Sendable {}

extension Split.Group: Sendable where Amount: Sendable {}

extension Split {
    // Inlinable so a split specializes into the caller instead of building this enum through
    // runtime metadata, which cost 112ns against 2ns.
    @inlinable
    func map<NewAmount>(
        _ transform: (Amount) -> NewAmount
    ) -> Split<NewAmount> {
        switch self {
        case let .even(group):
            return .even(
                .init(
                    count: group.count,
                    amount: transform(group.amount)
                )
            )
        case let .uneven(larger, smaller):
            return .uneven(
                larger: .init(
                    count: larger.count,
                    amount: transform(larger.amount)
                ),
                smaller: .init(
                    count: smaller.count,
                    amount: transform(smaller.amount)
                )
            )
        }
    }
}

// Not inlinable: the result is already concrete, so there is nothing for a caller to specialize.
@usableFromInline
func split(
    _ amount: Int64,
    into parts: PartCount
) -> Split<Int64> {
    guard let amount = NonZeroInt64(amount) else {
        return .even(.init(count: parts, amount: 0))
    }

    let (quotient, remainder) = amount.quotientAndRemainder(dividingBy: parts)

    switch remainder {
    case .zero:
        return .even(.init(count: parts, amount: quotient))
    case .nonZero(let nonZeroRemainder):
        // The remainder's magnitude is always less than the divisor, so `largerCount` is fewer than
        // `parts` and the subtraction below leaves at least one smaller part.
        let largerCount = abs(nonZeroRemainder)

        return .uneven(
            larger: .init(
                count: largerCount,
                amount: quotient + amount.signum
            ),
            smaller: .init(
                count: parts - largerCount,
                amount: quotient
            )
        )
    }
}

// Unchecked because a non-zero value has a magnitude of at least one.
//
// Narrowing to `Int` is safe here even though the value is an `Int64`: every caller passes a remainder,
// whose magnitude is always below the divisor — itself a `PartCount`, and so already within `Int`.
func abs(_ value: NonZeroInt64) -> PartCount {
    PartCount(unchecked: Int(abs(value.rawValue)))
}
