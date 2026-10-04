/// The parts of an even split: a number of parts that each receive the same amount.
///
/// What ``Split/even(_:)`` holds; only splitting an amount builds one.
///
/// ```swift
/// guard case let .even(even) = GBP(minorUnits: 9).split(into: 3) else { return }
/// even.amount   // GBP 0.03, and even.count is 3
/// ```
public struct EvenSplit<C: CurrencyRepresentation>: Equatable, Sendable {
    /// The number of parts the amount was split into.
    public let count: PartCount

    /// The amount each part receives, not the total.
    public let amount: MoneyOf<C>

    /// Creates the parts of an even split.
    ///
    /// `amount` times `count` is the amount that was split, so it is representable.
    ///
    /// - Parameters:
    ///   - count: The number of parts the amount was split into.
    ///   - amount: The amount each part receives.
    @inlinable
    init(
        count: PartCount,
        amount: MoneyOf<C>
    ) {
        // Not public: a caller could build parts whose total no amount can hold.
        self.count = count
        self.amount = amount
    }
}
