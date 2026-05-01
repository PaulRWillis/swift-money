/// The result of converting a `Money<From>` amount to `Money<To>` via an
/// ``ExchangeRate``.
///
/// `Conversion` bundles the converted amount with the
/// **actual rate that was applied** after rounding. Because money is stored as
/// a discrete integer number of minor units, fractional multiplication almost
/// always requires rounding, so the rate actually implied by the result
/// (`converted / inputAmount`) differs slightly from the nominal exchange rate.
///
/// ## Actual rate
///
/// ``actualRate`` is `nil` only when a non-zero input rounds to zero — i.e.
/// the input is so small that the converted amount is less than half a minor
/// unit of the target currency. In all other cases it is non-nil.
///
/// For zero input, ``actualRate`` equals the nominal exchange rate (the rate
/// is undefined for a zero amount, so the nominal rate is returned unchanged).
///
/// ## Round-trip invariant
///
/// When ``actualRate`` is non-nil and ``converted`` is non-zero, the following
/// holds exactly:
///
/// ```swift
/// inputAmount.multiplied(by: result.actualRate!.rate).result == result.converted
/// ```
///
/// ## Example
///
/// ```swift
/// let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
/// let r = rate.conversionResult(of: Money<EUR>(minorUnits: 101))
/// r.converted    // Money<GBP>(minorUnits: 86)         — €1.01 → £0.86
/// r.actualRate   // ExchangeRate<EUR, GBP>(from: 101, to: 86)
/// ```
public struct Conversion<From: Currency, To: Currency>: Sendable {

    // MARK: - Stored properties

    /// The converted amount expressed in `To`.
    public let converted: Money<To>

    /// The actual exchange rate implied by the rounded conversion.
    ///
    /// `nil` only when a non-zero input rounds to zero (the input amount is
    /// smaller than half a minor unit of `To` at the given rate). Non-nil for
    /// zero input and all non-zero results.
    public let actualRate: ExchangeRate<From, To>?

    // MARK: - Internal designated initialiser

    internal init(converted: Money<To>, actualRate: ExchangeRate<From, To>?) {
        self.converted = converted
        self.actualRate = actualRate
    }
}

// MARK: - Equatable

extension Conversion: Equatable {
    public static func == (
        lhs: Conversion,
        rhs: Conversion
    ) -> Bool {
        lhs.converted == rhs.converted && lhs.actualRate == rhs.actualRate
    }
}

// MARK: - Hashable

extension Conversion: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(converted)
        hasher.combine(actualRate)
    }
}
