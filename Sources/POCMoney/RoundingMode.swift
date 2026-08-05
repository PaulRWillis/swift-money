/// How to resolve part of a unit into a whole one.
///
/// The four modes that name a direction ignore how large the leftover part is; the two that name a
/// nearest choose by it, and differ only in how they break an exact tie.
///
/// - Note: `floor` and `ceiling` name a direction on the number line, not a size. On a negative
///   amount `floor` moves *away* from zero and `ceiling` moves toward it, which is the reverse of
///   what "round down" and "round up" mean in everyday speech.
public enum RoundingMode: Equatable, Hashable, Sendable {
    /// Discards the leftover part.
    case towardZero

    /// Always moves to the next whole unit, however small the leftover part.
    case awayFromZero

    /// Moves toward negative infinity.
    case floor

    /// Moves toward positive infinity.
    case ceiling

    /// Moves to the nearest whole unit; where two are equally close, to whichever is even.
    ///
    /// Banker's rounding, and the default IEEE 754 mode. Over many amounts it does not drift the way
    /// ``toNearestOrAwayFromZero`` does, because equally close values go each way equally often.
    case toNearestOrEven

    /// Moves to the nearest whole unit; where two are equally close, to the one of greater magnitude.
    ///
    /// Schoolbook rounding.
    case toNearestOrAwayFromZero
}
