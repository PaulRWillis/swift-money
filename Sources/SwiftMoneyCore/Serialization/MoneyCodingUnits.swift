/// Which units an amount's digits count, on the wire or in a string.
///
/// ```swift
/// .minorUnits   // 499
/// .majorUnits   // 4.99
/// ```
///
/// Reading, a `.` in a string always means major units, so this decides what digits without one
/// count: `"15"` is £15 in major units and 15p in minor. A number can never say, `400` and `400.00`
/// being one JSON number, so this decides what every number counts, and one with a fraction is
/// refused in minor units.
///
/// Name the units the sender writes. Nothing in `"GBP 499"` says which it meant, so an amount
/// written in one and read in the other is a hundredfold out.
public enum MoneyCodingUnits: Sendable, Equatable, Hashable {
    /// The currency's smallest units, so pence rather than pounds.
    case minorUnits

    /// Whole units and a fraction, so pounds and pence.
    case majorUnits
}
