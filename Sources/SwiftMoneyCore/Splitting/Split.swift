/// The result of splitting a monetary amount into a number of parts.
///
/// The parts always sum to the original amount, and no two parts differ by more than one minor
/// unit: a split does not lose or invent money.
///
/// ```swift
/// switch GBP(minorUnits: 100_00).split(into: 3) {    // a Split<Currencies.GBP>
/// case let .even(group): …                 // group.count parts of group.amount each
/// case let .uneven(larger, smaller): …     // 1 part of £33.34, then 2 parts of £33.33
/// }
/// ```
public enum Split<C: CurrencyRepresentation> {
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
        public let amount: MoneyOf<C>

        /// Creates a group of parts that each receive the same amount.
        ///
        /// - Parameters:
        ///   - count: The number of parts in the group.
        ///   - amount: The amount each part receives.
        @inlinable
        init(
            count: PartCount,
            amount: MoneyOf<C>
        ) {
            // Not public: a caller could pair a count with any amount.
            self.count = count
            self.amount = amount
        }
    }
}

extension Split {
    /// The number of parts the amount was split into.
    @inlinable
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
    /// let split = GBP(minorUnits: 100_00).split(into: 3)
    /// for amount in split.amounts { … }        // £33.34, £33.33, £33.33
    /// let all = Array(split.amounts)           // materializes, one element per part
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
    /// - Note: Iterating does not consume the sequence (it can be traversed repeatedly), though
    ///   `Sequence` does not promise that to generic code.
    @inlinable
    public var amounts: some Sequence<MoneyOf<C>> {
        Amounts(self)
    }

    @usableFromInline struct Amounts: Sequence {
        @usableFromInline let split: Split

        @inlinable init(_ split: Split) {
            self.split = split
        }

        @inlinable var underestimatedCount: Int {
            Int(split.count)
        }

        @inlinable func makeIterator() -> Iterator {
            Iterator(split)
        }

        // Everything about the split is settled once, in the initializer. Reading it out of the enum
        // per element meant recomputing `count` (itself a switch, two conversions and an addition)
        // on every call to `next()`, for a value that cannot change while iterating.
        @usableFromInline struct Iterator: IteratorProtocol {
            @usableFromInline let larger: MoneyOf<C>
            @usableFromInline let smaller: MoneyOf<C>
            @usableFromInline let largerCount: Int
            @usableFromInline let count: Int
            @usableFromInline var position = 0

            @inlinable init(_ split: Split) {
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

            @inlinable mutating func next() -> MoneyOf<C>? {
                guard position < count else {
                    return nil
                }

                defer { position += 1 }

                return position < largerCount ? larger : smaller
            }
        }
    }
}

extension Split: Equatable {}

extension Split: Sendable {}

extension Split.Group: Sendable {}

extension Split {
    /// Creates a split from one in minor units, giving every part the same currency.
    ///
    /// - Parameters:
    ///   - split: The split, in minor units.
    ///   - storage: What every part carries to know its currency.
    @inlinable
    init(
        _ split: MinorUnitSplit,
        storage: C.Storage
    ) {
        // Inlinable so a split specializes into the caller instead of building this enum through
        // runtime metadata.
        switch split {
        case let .even(count, minorUnits):
            self = .even(
                Group(
                    count: count,
                    amount: MoneyOf(unchecked: minorUnits, storage: storage)
                )
            )
        case let .uneven(largerCount, largerMinorUnits, smallerCount, smallerMinorUnits):
            self = .uneven(
                larger: Group(
                    count: largerCount,
                    amount: MoneyOf(unchecked: largerMinorUnits, storage: storage)
                ),
                smaller: Group(
                    count: smallerCount,
                    amount: MoneyOf(unchecked: smallerMinorUnits, storage: storage)
                )
            )
        }
    }
}

/// Returns an amount in minor units split into a number of parts, as evenly as possible.
///
/// - Parameters:
///   - amount: The minor units to split.
///   - parts: The number of parts to split into.
/// - Returns: The split, with larger parts one minor unit further from zero.
@usableFromInline
func split(
    _ amount: Int64,
    into parts: PartCount
) -> MinorUnitSplit {
    // Not inlinable: the result is already concrete, so there is nothing for a caller to
    // specialize.
    guard let amount = NonZeroInt64(amount) else {
        return .even(count: parts, minorUnits: 0)
    }

    let (quotient, remainder) = amount.quotientAndRemainder(dividingBy: parts)

    switch remainder {
    case .zero:
        return .even(count: parts, minorUnits: quotient)
    case .nonZero(let nonZeroRemainder):
        // The remainder's magnitude is always less than the divisor, so `largerCount` is fewer than
        // `parts` and the subtraction below leaves at least one smaller part.
        let largerCount = abs(nonZeroRemainder)

        return .uneven(
            largerCount: largerCount,
            largerMinorUnits: quotient + amount.signum,
            smallerCount: parts - largerCount,
            smallerMinorUnits: quotient
        )
    }
}

// Unchecked because a non-zero value has a magnitude of at least one.
//
// Narrowing to `Int` is safe here even though the value is an `Int64`: every caller passes a remainder,
// whose magnitude is always below the divisor, itself a `PartCount`, and so already within `Int`.
func abs(_ value: NonZeroInt64) -> PartCount {
    PartCount(unchecked: Int(abs(value.rawValue)))
}
