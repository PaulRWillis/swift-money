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
        // Hand-written because the synthesized `==` on this enum doesn't specialize across modules;
        // the synthesized `hash(into:)` and the payloads' `==` do.
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
        // Inlinable so a split specializes into the caller instead of building this enum through
        // runtime metadata.
        switch split {
        case let .even(count, minorUnits):
            self = .even(
                EvenSplit(
                    count: count,
                    amount: MoneyOf(unchecked: minorUnits, storage: storage)
                )
            )
        case let .uneven(largerCount, largerMinorUnits, smallerCount, smallerMinorUnits):
            self = .uneven(
                UnevenSplit(
                    largerCount: largerCount,
                    largerMinorUnits: largerMinorUnits,
                    smallerCount: smallerCount,
                    smallerMinorUnits: smallerMinorUnits,
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
