public extension FX {
    /// The rate at which one currency converts to another.
    ///
    /// Quoted the way a market quotes a pair: how many major units of `To` one major unit of `From`
    /// buys. A EUR/GBP rate of `0.87` means €1 buys £0.87. An exchange rate is strictly positive, and
    /// the currencies are part of the type, so a rate can only convert the currency it was quoted for
    /// and the direction cannot be mixed up.
    ///
    /// A provider's buy and sell rates for a pair are two rates, one each way. They are separate
    /// quotes, not reciprocals, so build each from its own quote rather than with ``inverted()``.
    ///
    /// ```swift
    /// let eurGbp = Rate(string: "0.87").flatMap(FX.ExchangeRate<Currencies.EUR, Currencies.GBP>.init)
    /// ```
    struct ExchangeRate<From: CurrencyType, To: CurrencyType>: Sendable, Equatable, Hashable {
        // Stored as `To` minor units per one `From` minor unit, the form `converted` and `crossed`
        // use directly. The public quote is per major unit; the two differ only when the currencies'
        // scales differ.
        @usableFromInline let minorPerMinorRate: Rate

        // Internal, not private: parsing a quote builds the stored rate from its own file.
        init?(minorPerMinor rate: Rate) {
            guard rate.isPositive else {
                return nil
            }

            self.minorPerMinorRate = rate
        }

        /// Creates an exchange rate from a market quote: `To` major units per one `From` major unit.
        ///
        /// The quote is never rounded. Use ``init(string:)`` to learn why a quote was refused.
        ///
        /// - Parameter marketRate: The market quote.
        /// - Returns: `nil` if the rate is not strictly positive (a zero or negative exchange rate
        ///   would zero or sign-flip a conversion), if it has more decimal places than a rate between
        ///   the two currencies holds, or if it is too large to hold.
        public init?(_ marketRate: Rate) {
            guard let rate = try? FX.minorPerMinorRate(
                significand: marketRate.value.storageBits,
                exponent: -Fixed.fractionalDigits,
                placesGained: Self.placesGained
            ) else {
                return nil
            }

            self.init(minorPerMinor: rate)
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

        /// Returns the rate the other way round: how many major units of `From` one major unit of
        /// `To` buys.
        ///
        /// The inverse is rounded to the nearest representable rate, so inverting twice may not give
        /// back this rate exactly. It is never a provider's sell rate, which is a quote of its own.
        ///
        /// ```swift
        /// let eurGbp = FX.ExchangeRate<Currencies.EUR, Currencies.GBP>("0.8")!
        /// let gbpEur = try eurGbp.inverted()   // 1.25
        /// ```
        ///
        /// - Returns: The inverse of this rate.
        /// - Throws: ``FX/ExchangeError/roundsToZero`` if the inverse is too close to zero to
        ///   represent.
        public func inverted() throws(ExchangeError) -> ExchangeRate<To, From> {
            // The inverse of `To` minor units per `From` minor unit is `From` per `To`, so it needs no
            // rescaling. A positive rate is at least 10⁻¹⁸, so the inverse is at most 10¹⁸ and the
            // divide can't overflow, only round to zero.
            guard let result = ExchangeRate<To, From>(
                minorPerMinor: Rate(Rate.par.value / minorPerMinorRate.value)
            ) else {
                throw .roundsToZero
            }

            return result
        }
    }
}
