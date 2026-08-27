/// How to resolve part of a unit into a whole one.
///
/// This is the standard library's own rounding rule, so it needs no conversion when handed to
/// `formatted(.currency.rounded(rule:))`, and a developer who knows `Double.rounded(_:)` already
/// knows it here.
///
/// The four rules that name a direction ignore how large the leftover part is; the two that name a
/// nearest choose by it, and differ only in how they break an exact tie.
///
/// - Note: `down` and `up` name a direction on the number line, not a size. On a negative amount
///   `down` moves *away* from zero and `up` moves toward it, which is the reverse of what "round
///   down" and "round up" mean in everyday speech.
///
/// - Note: The vocabulary **inverts** against the decimal arithmetic test suite this library's
///   rounding is validated with. Their `ROUND_DOWN` truncates toward zero, where `down` here moves
///   toward negative infinity:
///
///   | This library | decTest |
///   |---|---|
///   | `towardZero` | `ROUND_DOWN` |
///   | `awayFromZero` | `ROUND_UP` |
///   | `down` | `ROUND_FLOOR` |
///   | `up` | `ROUND_CEILING` |
///   | `toNearestOrEven` | `ROUND_HALF_EVEN` |
///   | `toNearestOrAwayFromZero` | `ROUND_HALF_UP` |
public typealias RoundingRule = FloatingPointRoundingRule
