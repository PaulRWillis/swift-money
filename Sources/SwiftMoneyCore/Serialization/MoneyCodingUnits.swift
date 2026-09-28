/// Which units an amount's digits count, on the wire or in a string.
///
/// ```swift
/// .minorUnits   // 499
/// .majorUnits   // 4.99
/// ```
///
/// A string says which it is for itself, a `.` meaning major units, so this decides only what a
/// number means. A number cannot say: `400` and `400.00` are one JSON number, and reading the
/// fraction as a hint would make the same payload mean two amounts a hundredfold apart.
public enum MoneyCodingUnits: Sendable, Equatable, Hashable {
    /// The currency's smallest units, so pence rather than pounds.
    case minorUnits

    /// Whole units and a fraction, so pounds and pence.
    case majorUnits
}
