/// A margin taken on an exchange rate — the spread a provider keeps, given up by the customer.
///
/// A margin is at least zero and less than one whole: applying it gives back a fraction of the mid
/// rate, never zero and never a larger or inverted rate. Build one from a rate written as a percentage
/// or in basis points:
///
/// ```swift
/// let margin = Margin(.basisPoints(5))   // five basis points, 0.05%
/// let markup = Margin(.percent(2))       // two percent
/// ```
public struct Margin: Sendable, Equatable {
    let rate: Rate

    /// Creates a margin from a rate.
    ///
    /// - Returns: `nil` unless the rate is at least zero and less than one — a negative margin, or one
    ///   of a whole or more, is not a spread a provider can take.
    public init?(_ rate: Rate) {
        guard rate.isFractionOfWhole else {
            return nil
        }

        self.rate = rate
    }
}
