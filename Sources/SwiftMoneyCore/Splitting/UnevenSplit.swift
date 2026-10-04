/// The parts of an uneven split, whose larger parts are one minor unit further from zero.
///
/// What ``Split/uneven(_:)`` holds; only splitting an amount builds one. Larger and smaller
/// compare by magnitude, so a refund's larger parts are the more negative ones.
///
/// ```swift
/// guard case let .uneven(uneven) = GBP(minorUnits: -10).split(into: 3) else { return }
/// uneven.largerAmount   // GBP -0.04, and uneven.smallerAmount is GBP -0.03
/// ```
public struct UnevenSplit<C: CurrencyRepresentation>: Equatable, Sendable {
    /// The number of parts that receive ``largerAmount``, fewer than ``count``.
    public let largerCount: PartCount

    /// The amount each larger part receives, one minor unit further from zero than
    /// ``smallerAmount``.
    public let largerAmount: MoneyOf<C>

    /// The number of parts that receive ``smallerAmount``, fewer than ``count``.
    public let smallerCount: PartCount

    /// The amount each smaller part receives.
    public let smallerAmount: MoneyOf<C>

    /// The number of parts the amount was split into.
    @inlinable
    public var count: PartCount {
        // A split's two counts sum to the part count it was given, so this can't overflow.
        PartCount(unchecked: Int(largerCount) + Int(smallerCount))
    }

    /// Creates the parts of an uneven split.
    ///
    /// Same currency, with `largerAmount` one minor unit further from zero.
    /// The counts sum to the number of parts the amount was split into, at most `Int.max`.
    ///
    /// - Parameters:
    ///   - largerCount: The number of parts that receive `largerAmount`.
    ///   - largerAmount: The amount each larger part receives.
    ///   - smallerCount: The number of parts that receive `smallerAmount`.
    ///   - smallerAmount: The amount each smaller part receives.
    @inlinable
    init(
        largerCount: PartCount,
        largerAmount: MoneyOf<C>,
        smallerCount: PartCount,
        smallerAmount: MoneyOf<C>
    ) {
        // Not public: a caller could pair counts and amounts from different splits.
        self.largerCount = largerCount
        self.largerAmount = largerAmount
        self.smallerCount = smallerCount
        self.smallerAmount = smallerAmount
    }
}
