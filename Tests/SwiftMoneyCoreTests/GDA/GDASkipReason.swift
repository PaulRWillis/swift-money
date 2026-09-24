/// Why a General Decimal Arithmetic vector was not run against the engine.
///
/// The corpus covers a full decimal floating-point specification; this library is a fixed-point money
/// engine, so many vectors fall outside what it can represent or what it promises. Skips are counted and
/// reported per operation so an unexpected jump in a category is visible, rather than silently shrinking
/// the set of vectors that actually run.
enum GDASkipReason: String, CaseIterable, Sendable {
    /// An operation the engine does not offer (for example remainder, power, square root).
    case unsupportedOperation

    /// A rounding mode the engine does not have (`half_down`, `05up`), or a non-half-even mode on an
    /// operation the engine only rounds half-even (multiply, divide).
    case unsupportedRounding

    /// An operand or the expected result carries more fractional digits than the engine keeps, or the
    /// vector's own rounding makes it a test of decimal-significance rounding the fixed-point engine does
    /// not perform.
    case precision

    /// An operand or the expected result is outside the engine's representable range.
    case outOfRange

    /// An operand or the expected result is a value the engine has no representation for (NaN, infinity).
    case notRepresentable

    /// The vector expects an exceptional condition (overflow, division by zero, invalid operation); the
    /// engine traps on these rather than returning a sentinel, so the result cannot be compared.
    case expectsTrap
}
