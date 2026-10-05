/// The parts of an uneven split, whose larger parts are one minor unit further from zero.
///
/// What ``Split/uneven(_:)`` holds; only splitting an amount builds one. Larger and smaller
/// compare by magnitude, so a refund's larger parts are the more negative ones.
///
/// ```swift
/// guard case let .uneven(uneven) = GBP(minorUnits: -10).split(into: 3) else { return }
/// uneven.largerAmount   // GBP -0.04, and uneven.smallerAmount is GBP -0.03
/// ```
public struct UnevenSplit<C: CurrencyRepresentation>: Equatable, Hashable, Sendable {
    /// The number of parts that receive ``largerAmount``, fewer than ``count``.
    public let largerCount: PartCount

    /// The number of parts that receive ``smallerAmount``, fewer than ``count``.
    public let smallerCount: PartCount

    /// The minor units each larger part receives, one further from zero than
    /// ``smallerMinorUnits``.
    @usableFromInline let largerMinorUnits: Int64

    /// The minor units each smaller part receives.
    @usableFromInline let smallerMinorUnits: Int64

    /// The currency storage both amounts are built from.
    @usableFromInline let storage: C.Storage

    /// The amount each larger part receives, one minor unit further from zero than
    /// ``smallerAmount``.
    @inlinable
    public var largerAmount: MoneyOf<C> {
        MoneyOf(unchecked: largerMinorUnits, storage: storage)
    }

    /// The amount each smaller part receives.
    @inlinable
    public var smallerAmount: MoneyOf<C> {
        MoneyOf(unchecked: smallerMinorUnits, storage: storage)
    }

    /// The number of parts the amount was split into.
    @inlinable
    public var count: PartCount {
        // A split's two counts sum to the part count it was given, so this can't overflow.
        PartCount(unchecked: Int(largerCount) + Int(smallerCount))
    }

    /// Creates the parts of an uneven split.
    ///
    /// `largerMinorUnits` is one minor unit further from zero than `smallerMinorUnits`. The
    /// counts sum to the number of parts the amount was split into, at most `Int.max`. The
    /// amounts times their counts sum to the amount that was split, so the total fits in `Int64`.
    ///
    /// - Parameters:
    ///   - largerCount: The number of parts that receive the larger amount.
    ///   - largerMinorUnits: The minor units each larger part receives.
    ///   - smallerCount: The number of parts that receive the smaller amount.
    ///   - smallerMinorUnits: The minor units each smaller part receives.
    ///   - storage: The currency storage both amounts are built from.
    @inlinable
    init(
        largerCount: PartCount,
        largerMinorUnits: Int64,
        smallerCount: PartCount,
        smallerMinorUnits: Int64,
        storage: C.Storage
    ) {
        // Not public: a caller could pair counts and amounts from different splits.
        self.largerCount = largerCount
        self.largerMinorUnits = largerMinorUnits
        self.smallerCount = smallerCount
        self.smallerMinorUnits = smallerMinorUnits
        self.storage = storage
    }

    /// Returns whether two uneven splits are equal.
    ///
    /// Uneven splits are equal when their counts and amounts match, currency included.
    ///
    /// ```swift
    /// guard case let .uneven(a) = GBP(minorUnits: 11).split(into: 3),
    ///       case let .uneven(b) = GBP(minorUnits: 10).split(into: 3) else { return }
    /// a == a   // true
    /// a == b   // false
    /// ```
    ///
    /// - Parameters:
    ///   - lhs: An uneven split to compare.
    ///   - rhs: Another uneven split to compare.
    /// - Returns: `true` if the uneven splits are equal; otherwise, `false`.
    @inlinable
    public static func == (lhs: UnevenSplit, rhs: UnevenSplit) -> Bool {
        // Hand-written because the synthesized `==` doesn't specialize across modules.
        lhs.largerCount == rhs.largerCount
            && lhs.smallerCount == rhs.smallerCount
            && lhs.largerMinorUnits == rhs.largerMinorUnits
            && lhs.smallerMinorUnits == rhs.smallerMinorUnits
            && lhs.storage == rhs.storage
    }
}

#if !hasFeature(Embedded)

extension UnevenSplit: CustomReflectable {
    /// A mirror showing the counts and amounts of the larger and smaller parts.
    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "largerCount": largerCount,
                "largerAmount": largerAmount,
                "smallerCount": smallerCount,
                "smallerAmount": smallerAmount,
            ],
            displayStyle: .struct
        )
    }
}

#endif
