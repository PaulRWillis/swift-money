/// The rate at which one currency converts to another: how many minor units of `To` one minor unit of
/// `From` buys.
///
/// An exchange rate is strictly positive. The currencies are part of the type, so a rate can only be
/// used to convert the currency it was quoted for, and the direction cannot be mixed up.
///
/// ```swift
/// let eurGbp = ExchangeRate<Currencies.EUR, Currencies.GBP>(quoting: 87, per: 100)
/// ```
public struct ExchangeRate<From: CurrencyType, To: CurrencyType>: Sendable, Equatable {
    let rate: Rate

    /// Creates an exchange rate from a rate.
    ///
    /// - Returns: `nil` unless the rate is strictly positive — a zero or negative exchange rate would
    ///   zero or sign-flip a conversion.
    public init?(_ rate: Rate) {
        guard rate.isPositive else {
            return nil
        }

        self.rate = rate
    }

    /// Creates an exchange rate from a quoted pair of minor-unit amounts, as a feed gives them.
    ///
    /// `ExchangeRate(quoting: 87, per: 100)` is the rate that buys 87 minor units of `To` for every 100
    /// of `From`.
    ///
    /// - Returns: `nil` if `fromMinorUnits` is zero, or the quoted rate is not strictly positive.
    public init?(quoting toMinorUnits: Int64, per fromMinorUnits: Int64) {
        guard fromMinorUnits != 0 else {
            return nil
        }

        self.init(Rate(Fixed(toMinorUnits) / Fixed(fromMinorUnits)))
    }

    /// Returns the customer rate for this mid-market rate: the rate less the provider's margin.
    ///
    /// The customer keeps the fraction of the mid rate the margin does not take, so the result is
    /// always positive and never larger than the mid rate.
    public func applyingMargin(_ margin: Margin) -> Self {
        // margin is in [0, 1), so the kept fraction is in (0, 1] and the product stays positive and no
        // larger than `rate` — it cannot leave the range or the positive invariant.
        guard let customer = rate.multiplied(by: margin.rate.subtracted(from: .par)),
              let result = Self(customer) else {
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
        guard let composed = rate.multiplied(by: other.rate),
              let result = ExchangeRate<From, Onward>(composed) else {
            preconditionFailure("Crossing two rates left the representable range")  // coverage:ignore — exit-test trap
        }

        return result
    }
}
