/// The result of converting a multi-currency ``MoneyBag`` to a single currency.
///
/// `MoneyConversionResult` exposes both the final rounded monetary total and
/// the **exact rational value** that was rounded, expressed as a reduced
/// fraction (`exactNumerator / exactDenominator`). The exact fraction lets
/// callers audit how much precision was lost and how it was distributed.
///
/// ## Invariants
///
/// The following always hold for a non-nil result:
///
/// ```
/// round(exactNumerator / exactDenominator)  ==  total.minorUnits
/// |exactNumerator − total.minorUnits × exactDenominator|  <  exactDenominator / 2
/// ```
///
/// where `round(…)` uses the same `rounding` rule that was passed to
/// ``MoneyBag/total(in:using:rounding:)``.
///
/// ## Residual
///
/// The signed rounding residual is:
/// ```
/// residual = exactNumerator − total.minorUnits × exactDenominator
/// ```
/// A positive residual means the exact total was slightly above the rounded value
/// (rounding down absorbed the fractional part). A negative residual means rounding
/// up was applied.
///
/// ## Single rounding guarantee
///
/// Unlike a naïve approach that rounds each currency conversion separately,
/// ``MoneyBag/total(in:using:rounding:)`` accumulates all conversions as
/// **exact integer fractions** (using ``exactNumerator`` / ``exactDenominator``)
/// and applies exactly **one rounding event**, no matter how many currencies
/// are in the bag. This guarantees that the rounding error is bounded by
/// `0.5` minor units regardless of bag size.
///
/// ## Exact rates
///
/// When all exchange rates produce integer minor-unit amounts with no remainder
/// (e.g. a 1:1 identity rate or any rate where the minor-unit amounts divide
/// evenly), ``exactDenominator`` is `1` and `exactNumerator == total.minorUnits`.
///
/// ## Example
///
/// ```swift
/// // £10.05 USD + £200 GBP + £503 JPY, converted to GBP:
/// //   exact total = 30614277 / 400 = 76535.6925 GBP pence
/// //   total       = Money<GBP>(minorUnits: 76536)  i.e. £765.36
/// //   residual    = 30614277 − 76536 × 400 = −123   (in 400ths of a penny)
/// let result = bag.total(in: GBP.self, using: provider)!
/// result.total             // Money<GBP>(minorUnits: 76536) — £765.36
/// result.exactNumerator    // 30614277
/// result.exactDenominator  // 400
/// ```
public struct MoneyConversionResult<C: Currency>: Sendable {

    // MARK: - Stored properties

    /// The final rounded monetary amount in currency `C`.
    public let total: Money<C>

    /// The numerator of the exact (unrounded) total in minor units of `C`,
    /// expressed as a GCD-reduced fraction `exactNumerator / exactDenominator`.
    ///
    /// Divide by ``exactDenominator`` to recover the exact fractional minor-unit count.
    public let exactNumerator: Int128

    /// The denominator of the exact (unrounded) total. Always positive.
    ///
    /// Equal to `1` when all conversions were exact (no remainder).
    public let exactDenominator: Int128

    // MARK: - Internal designated initialiser

    internal init(total: Money<C>, exactNumerator: Int128, exactDenominator: Int128) {
        self.total = total
        self.exactNumerator = exactNumerator
        self.exactDenominator = exactDenominator
    }
}

// MARK: - Equatable

extension MoneyConversionResult: Equatable {
    public static func == (lhs: MoneyConversionResult, rhs: MoneyConversionResult) -> Bool {
        lhs.total == rhs.total
            && lhs.exactNumerator == rhs.exactNumerator
            && lhs.exactDenominator == rhs.exactDenominator
    }
}

// MARK: - Hashable

extension MoneyConversionResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(total)
        hasher.combine(exactNumerator)
        hasher.combine(exactDenominator)
    }
}
