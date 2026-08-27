/// The rate at which one currency converts to another.
///
/// Quoted the way a market quotes a pair: how many major units of `To` one major unit of `From` buys.
/// A EUR/GBP rate of `0.87` means €1 buys £0.87. An exchange rate is strictly positive, and the
/// currencies are part of the type, so a rate can only convert the currency it was quoted for and the
/// direction cannot be mixed up.
///
/// ```swift
/// let eurGbp = ExchangeRate<Currencies.EUR, Currencies.GBP>(quoting: 87, per: 100)
/// ```
public struct ExchangeRate<From: CurrencyType, To: CurrencyType>: Sendable, Equatable {
    // Stored as `To` minor units per one `From` minor unit — the form `converted` and `crossed` use
    // directly. The public quote is per major unit; the two differ only when the currencies' scales
    // differ, and the conversion between them lives solely in `init?(_:)`.
    let minorPerMinorRate: Rate

    private init?(minorPerMinor rate: Rate) {
        guard rate.isPositive else {
            return nil
        }

        self.minorPerMinorRate = rate
    }

    /// Creates an exchange rate from a market quote: `To` major units per one `From` major unit.
    ///
    /// - Returns: `nil` unless the rate is strictly positive — a zero or negative exchange rate would
    ///   zero or sign-flip a conversion.
    public init?(_ marketRate: Rate) {
        // A major-unit rate scaled to minor units: multiplying a `From`-minor amount by the result
        // gives a `To`-minor amount. `× toScale ÷ fromScale` converts between the two quote forms —
        // e.g. $1 = ¥149.5 (per major) becomes 1.495 ¥-minor per ¢, since ¥ has scale 1 and $ has 100.
        let scaled = marketRate.value
            .multiplied(by: Int64(To.currency.unitScale))
            .divided(by: Int64(From.currency.unitScale))

        self.init(minorPerMinor: Rate(scaled))
    }

    /// Creates an exchange rate from a quoted pair of minor-unit amounts, as a feed gives them.
    ///
    /// `ExchangeRate(quoting: 87, per: 100)` is the rate at which 100 minor units of `From` are worth 87
    /// minor units of `To`.
    ///
    /// - Returns: `nil` if `fromMinorUnits` is zero, or the quoted rate is not strictly positive.
    public init?(quoting toMinorUnits: Int64, per fromMinorUnits: Int64) {
        guard fromMinorUnits != 0 else {
            return nil
        }

        self.init(minorPerMinor: Rate(Fixed(toMinorUnits) / Fixed(fromMinorUnits)))
    }

    /// Returns the customer rate for this mid-market rate: the rate less the provider's margin.
    ///
    /// The customer keeps the fraction of the mid rate the margin does not take, so the result is
    /// always positive and never larger than the mid rate.
    public func applyingMargin(_ margin: Margin) -> Self {
        // margin is in [0, 1), so the kept fraction is in (0, 1] and the product stays positive and no
        // larger than the rate — it cannot leave the range or the positive invariant.
        guard let customer = minorPerMinorRate.multiplied(by: margin.rate.subtracted(from: .par)),
              let result = Self(minorPerMinor: customer) else {
            preconditionFailure("Applying a margin left the representable range")  // coverage:ignore — exit-test trap
        }

        return result
    }

    /// Returns the rate that converts `From` all the way to `Onward`, via this rate and `other`.
    ///
    /// The shared currency is enforced by the types: this rate's `To` must be `other`'s `From`, so
    /// `EUR→GBP` is `EUR→USD` crossed with `USD→GBP`.
    ///
    /// - Precondition: the composed rate is representable, which any realistic pair of rates is.
    public func crossed<Onward>(
        with other: ExchangeRate<To, Onward>
    ) -> ExchangeRate<From, Onward> {
        // Both are minor-per-minor, so the shared `To` minor unit cancels and the product is already
        // `Onward` minor units per one `From` minor unit — no scale adjustment needed.
        guard let composed = minorPerMinorRate.multiplied(by: other.minorPerMinorRate),
              let result = ExchangeRate<From, Onward>(minorPerMinor: composed) else {
            preconditionFailure("Crossing two rates left the representable range")  // coverage:ignore — exit-test trap
        }

        return result
    }
}
