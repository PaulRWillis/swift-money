public enum Split<Amount: Equatable> {
    case even(Group)

    /// Some parts receive one more minor unit than the others.
    ///
    /// `larger` and `smaller` compare by *magnitude*, not numerically: splitting a refund of
    /// `-10` into three gives `larger` of one part at `-4` and `smaller` of two parts at `-3`,
    /// because a refund of 4 is larger than a refund of 3.
    case uneven(
        larger: Group,
        smaller: Group
    )
}

extension Split {
    public struct Group: Equatable {
        public let count: PartCount
        public let amount: Amount

        fileprivate init(
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

        struct Iterator: IteratorProtocol {
            private let split: Split
            private var position = 0

            fileprivate init(_ split: Split) {
                self.split = split
            }

            mutating func next() -> Amount? {
                guard position < Int(split.count) else {
                    return nil
                }

                defer { position += 1 }

                switch split {
                case let .even(group):
                    return group.amount
                case let .uneven(larger, smaller):
                    return position < Int(larger.count) ? larger.amount : smaller.amount
                }
            }
        }
    }
}

extension Split {
    static func even(count: PartCount, amount: Amount) -> Self {
        self.even(
            Group(
                count: count,
                amount: amount
            )
        )
    }

    static func uneven(
        larger: (count: PartCount, amount: Amount),
        smaller: (count: PartCount, amount: Amount),
    ) -> Self {
        self.uneven(
            larger: Group(
                count: larger.count,
                amount: larger.amount
            ),
            smaller: Group(
                count: smaller.count,
                amount: smaller.amount
            )
        )
    }
}

// MARK: - Equatable

extension Split: Equatable {}

extension Split {
    func map<NewAmount>(
        _ transform: (Amount) -> NewAmount
    ) -> Split<NewAmount> {
        switch self {
        case let .even(group):
            return .even(
                count: group.count,
                amount: transform(group.amount)
            )
        case let .uneven(larger, smaller):
            return .uneven(
                larger: (
                    count: larger.count,
                    amount: transform(larger.amount)
                ),
                smaller: (
                    count: smaller.count,
                    amount: transform(smaller.amount)
                ),
            )
        }
    }
}

func split(
    _ amount: Int,
    into parts: PartCount
) -> Split<Int> {
    guard let amount = NonZeroInt(amount) else {
        return .even(count: parts, amount: 0)
    }

    let (quotient, remainder) = amount.quotientAndRemainder(dividingBy: parts)

    switch remainder {
    case .zero:
        return .even(count: parts, amount: quotient)
    case .nonZero(let nonZeroRemainder):
        let largerCount = abs(nonZeroRemainder)

        return .uneven(
            larger: (
                count: largerCount,
                amount: quotient + amount.signum
            ),
            smaller: (
                count: parts.subtracting(largerCount),
                amount: quotient
            )
        )
    }
}

func abs(_ value: NonZeroInt) -> PartCount {
    PartCount(unchecked: abs(value.rawValue))
}
