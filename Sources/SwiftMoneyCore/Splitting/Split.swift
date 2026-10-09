/// The result of splitting a monetary amount into a number of parts.
///
/// The parts always sum to the original amount, and no two parts differ by more than one minor
/// unit: a split does not lose or invent money.
///
/// ```swift
/// switch GBP(minorUnits: 100_00).split(into: 3) {    // a Split<Currencies.GBP>
/// case let .even(even): …        // even.count parts of even.amount each
/// case let .uneven(uneven): …    // 1 part of £33.34, then 2 parts of £33.33
/// }
/// ```
public enum Split<C: CurrencyRepresentation> {
    /// An even split, holding its part count and the amount each part receives.
    case even(EvenSplit<C>)

    /// An uneven split, holding the counts and amounts of its larger and smaller parts.
    case uneven(UnevenSplit<C>)
}

extension Split {
    /// The number of parts the amount was split into.
    @inlinable
    public var count: PartCount {
        switch self {
        case let .even(even):
            return even.count
        case let .uneven(uneven):
            return uneven.count
        }
    }

    /// Every part's amount, one element per part, larger amounts first.
    ///
    /// Iterating allocates nothing, however many parts the split has.
    ///
    /// ```swift
    /// let split = GBP(minorUnits: 100_00).split(into: 3)
    /// for amount in split.amounts { … }        // £33.34, £33.33, £33.33
    /// let all = Array(split.amounts)           // [£33.34, £33.33, £33.33]
    /// ```
    ///
    /// - Note: For the number of amounts, use ``Split/count``.
    ///
    /// - Note: The amounts can be iterated more than once.
    @inlinable
    public var amounts: some Sequence<MoneyOf<C>> {
        Amounts(self)
    }

    /// A split's amounts, one per part.
    @usableFromInline struct Amounts: Sequence {
        /// The split to iterate.
        @usableFromInline let split: Split

        /// Creates the amounts of a split.
        ///
        /// - Parameter split: The split to iterate.
        @inlinable init(_ split: Split) {
            self.split = split
        }

        /// The number of parts, which is exactly the number of amounts.
        @inlinable var underestimatedCount: Int {
            Int(split.count)
        }

        /// Returns an iterator over the split's amounts.
        ///
        /// - Returns: A new iterator, starting at the first part.
        @inlinable func makeIterator() -> Iterator {
            Iterator(split)
        }

        /// An iterator over a split's amounts, larger amounts first.
        @usableFromInline struct Iterator: IteratorProtocol {
            /// The amount of each larger part.
            @usableFromInline let larger: MoneyOf<C>

            /// The amount of each smaller part, equal to ``larger`` for an even split.
            @usableFromInline let smaller: MoneyOf<C>

            /// The number of parts that receive ``larger``.
            @usableFromInline let largerCount: Int

            /// The number of parts, which is the number of amounts the iterator returns.
            @usableFromInline let count: Int

            /// The number of amounts returned so far.
            @usableFromInline var position = 0

            /// Creates an iterator over a split's amounts.
            ///
            /// - Parameter split: The split to iterate.
            @inlinable init(_ split: Split) {
                switch split {
                case let .even(even):
                    larger = even.amount
                    smaller = even.amount
                    largerCount = Int(even.count)
                    count = largerCount
                case let .uneven(uneven):
                    larger = uneven.largerAmount
                    smaller = uneven.smallerAmount
                    largerCount = Int(uneven.largerCount)
                    count = largerCount + Int(uneven.smallerCount)
                }
            }

            /// Returns the next amount, or `nil` once every part has been returned.
            ///
            /// - Returns: The next part's amount, or `nil` if there are no more.
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

extension Split: Equatable {
    /// Returns whether two splits are equal.
    ///
    /// Splits are equal when both are even or both uneven, and their counts and amounts match.
    ///
    /// ```swift
    /// GBP(minorUnits: 9).split(into: 3) == GBP(minorUnits: 9).split(into: 3)    // true
    /// GBP(minorUnits: 9).split(into: 3) == GBP(minorUnits: 10).split(into: 3)   // false
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: A split to compare.
    ///   - rhs: Another split to compare.
    /// - Returns: `true` if the splits are equal; otherwise, `false`.
    @inlinable
    public static func == (lhs: Split, rhs: Split) -> Bool {
        // Hand-written because the synthesized `==` doesn't specialize across modules.
        switch (lhs, rhs) {
        case let (.even(left), .even(right)):
            return left == right
        case let (.uneven(left), .uneven(right)):
            return left == right
        case (.even, .uneven), (.uneven, .even):
            return false
        }
    }
}

extension Split: Sendable {}

extension Split: Hashable {}

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
        switch split {
        case let .even(count, minorUnits):
            self = .even(
                EvenSplit(
                    count: count,
                    amount: MoneyOf(unchecked: minorUnits, storage: storage)
                )
            )
        case let .uneven(largerCount, largerMinorUnits, smallerCount):
            self = .uneven(
                UnevenSplit(
                    largerCount: largerCount,
                    largerMinorUnits: largerMinorUnits,
                    smallerCount: smallerCount,
                    storage: storage
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
    _ amount: Money.MinorUnits,
    into parts: PartCount
) -> MinorUnitSplit {
    guard let amount = NonZero(amount) else {
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
            // The quotient is zero or has the amount's sign, so adding the sign moves it away
            // from zero. Two or more parts keep it at most half the amount, so it can't overflow.
            largerMinorUnits: NonZero(unchecked: quotient + amount.signum),
            smallerCount: parts - largerCount
        )
    }
}

/// Returns the magnitude of a non-zero value as a part count.
///
/// - Parameter value: The value to measure.
/// - Returns: The magnitude of `value`.
/// - Precondition: The magnitude of `value` must fit in `Int`.
func abs(_ value: NonZero<Money.MinorUnits>) -> PartCount {
    // A non-zero value's magnitude is at least one, so it's a valid part count.
    PartCount(unchecked: Int(abs(value.rawValue)))
}
