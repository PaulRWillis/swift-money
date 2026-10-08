public extension FX {
    /// The rate at which one currency converts to another.
    ///
    /// Quoted the way a market quotes a pair: how many major units of `To` one major unit of `From`
    /// buys. A EUR/GBP rate of `0.87` means €1 buys £0.87. An exchange rate is strictly positive, and
    /// the currencies are part of the type, so a rate can only convert the currency it was quoted for
    /// and the direction cannot be mixed up.
    ///
    /// ```swift
    /// let eurGbp = Rate(string: "0.87").flatMap(FX.ExchangeRate<Currencies.EUR, Currencies.GBP>.init)
    /// ```
    struct ExchangeRate<From: CurrencyType, To: CurrencyType>: Sendable, Equatable {
        // Stored as `To` minor units per one `From` minor unit, the form `converted` and `crossed`
        // use directly. The public quote is per major unit; the two differ only when the currencies'
        // scales differ, and the conversion between them lives solely in `init?(_:)`.
        @usableFromInline let minorPerMinorRate: Rate

        private init?(minorPerMinor rate: Rate) {
            guard rate.isPositive else {
                return nil
            }

            self.minorPerMinorRate = rate
        }

        /// Creates an exchange rate from a market quote: `To` major units per one `From` major unit.
        ///
        /// - Returns: `nil` if the rate is not strictly positive (a zero or negative exchange rate
        ///   would zero or sign-flip a conversion), or if rescaling it between the two currencies
        ///   overflows the representable range.
        public init?(_ marketRate: Rate) {
            // A major-unit rate scaled to minor units: multiplying a `From`-minor amount by the result
            // gives a `To`-minor amount. `× toScale ÷ fromScale` converts between the two quote
            // forms. For example, $1 = ¥149.5 (per major) becomes 1.495 ¥-minor per ¢, since ¥ has
            // scale 1 and $ has 100. The multiply is checked because the two scales can differ widely
            // enough to overflow; the divide that follows only shrinks an already-representable value,
            // so it cannot.
            guard let scaled = marketRate.value
                .multipliedIfRepresentable(by: Int128(Int64(To.currency.unitScale)))?
                .divided(by: Fixed.Divisor(From.currency.unitScale)) else {
                return nil
            }

            self.init(minorPerMinor: Rate(scaled))
        }

        /// Returns the customer rate for this mid-market rate: the rate less the provider's margin.
        ///
        /// The customer keeps the fraction of the mid rate the margin does not take, so the result is
        /// never larger than the mid rate.
        ///
        /// ```swift
        /// let mid = FX.ExchangeRate<Currencies.EUR, Currencies.GBP>("1.5")!
        /// let margin = FX.Margin(.percent(20))!
        /// let customer = try mid.applyingMargin(margin)   // 1.2
        /// ```
        ///
        /// - Parameter margin: The provider's margin.
        /// - Returns: The mid rate less `margin`.
        /// - Throws: ``FX/ExchangeError/roundsToZero`` if the customer rate is too close to zero to
        ///   represent.
        public func applyingMargin(_ margin: Margin) throws(ExchangeError) -> Self {
            // margin is in [0, 1), so the kept fraction is in (0, 1] and the product is no larger than
            // the rate: it can't overflow, only round to zero.
            guard let customer = minorPerMinorRate.multiplied(by: margin.rate.subtracted(from: .par)),
                  let result = Self(minorPerMinor: customer) else {
                throw .roundsToZero
            }

            return result
        }

        /// Returns the rate that converts `From` all the way to `Onward`, via this rate and `other`.
        ///
        /// The shared currency is enforced by the types: this rate's `To` must be `other`'s `From`, so
        /// `EUR→GBP` is `EUR→USD` crossed with `USD→GBP`.
        ///
        /// ```swift
        /// let eurUsd = FX.ExchangeRate<Currencies.EUR, Currencies.USD>("1.1")!
        /// let usdGbp = FX.ExchangeRate<Currencies.USD, Currencies.GBP>("0.8")!
        /// let eurGbp = try eurUsd.crossed(with: usdGbp)   // 0.88
        /// ```
        ///
        /// - Parameter other: The rate from this rate's `To` currency onward.
        /// - Returns: The product of this rate and `other`.
        /// - Throws: ``FX/ExchangeError/overflow`` if the product is too large to represent;
        ///   ``FX/ExchangeError/roundsToZero`` if it is too close to zero to represent.
        public func crossed<Onward>(
            with other: ExchangeRate<To, Onward>
        ) throws(ExchangeError) -> ExchangeRate<From, Onward> {
            // Both are minor-per-minor, so the shared `To` minor unit cancels and the product is
            // already `Onward` minor units per one `From` minor unit, with no scale adjustment needed.
            guard let composed = minorPerMinorRate.multiplied(by: other.minorPerMinorRate) else {
                throw .overflow
            }
            guard let result = ExchangeRate<From, Onward>(minorPerMinor: composed) else {
                throw .roundsToZero
            }

            return result
        }
    }
}
