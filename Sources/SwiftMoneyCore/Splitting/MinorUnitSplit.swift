/// A number of minor units split into a number of parts, with no currency.
@usableFromInline
enum MinorUnitSplit: Hashable, Sendable {
    /// An even split: the part count and each part's minor units.
    case even(count: PartCount, minorUnits: Int64)

    /// An uneven split: each group's part count, and the larger group's minor units, which are
    /// never zero. The smaller group's are one unit nearer zero.
    case uneven(
        largerCount: PartCount,
        largerMinorUnits: NonZeroInt64,
        smallerCount: PartCount
    )
}
