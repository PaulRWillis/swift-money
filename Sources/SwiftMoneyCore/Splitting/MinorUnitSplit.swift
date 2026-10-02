/// A number of minor units split into a number of parts, with no currency.
@usableFromInline
enum MinorUnitSplit: Hashable, Sendable {
    /// An even split: the part count and each part's minor units.
    case even(count: PartCount, minorUnits: Int64)

    /// An uneven split: each group's part count and minor units, the larger further from zero.
    case uneven(
        largerCount: PartCount,
        largerMinorUnits: Int64,
        smallerCount: PartCount,
        smallerMinorUnits: Int64
    )
}
