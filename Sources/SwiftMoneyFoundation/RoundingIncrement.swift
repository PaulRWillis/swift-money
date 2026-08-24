/// The step a format style rounds a displayed amount to.
///
/// Counted in the currency's smallest units, so a five-centime rounding is `5` whatever the
/// currency's scale turns out to be. Always at least one: a step of zero or less has no
/// meaning, so those values cannot be constructed.
public struct RoundingIncrement: Equatable, Hashable, Sendable {
    fileprivate let rawValue: Int64

    /// Creates a rounding increment from a value that may not be valid.
    ///
    /// - Parameter value: The step, counted in the currency's smallest units.
    /// - Returns: `nil` if `value` is less than one.
    public init?(exactly value: Int64) {
        guard value >= 1 else {
            return nil
        }

        self.rawValue = value
    }
}

public extension Int64 {
    /// Creates an integer from a rounding increment.
    ///
    /// - Parameter increment: The rounding increment to convert.
    init(_ increment: RoundingIncrement) {
        self = increment.rawValue
    }
}
