public extension FX {
    /// The rate at which one currency converts to another.
    ///
    /// Quoted the way a market quotes a pair: how many major units of `To` one major unit of `From`
    /// buys. A EUR/GBP rate of `0.87` means €1 buys £0.87. An exchange rate is strictly positive, and
    /// the currencies are part of the type, so a rate can only convert the currency it was quoted for
    /// and the direction cannot be mixed up.
    ///
    /// Converting an amount at a rate is in the `SwiftMoneyFX` module.
    ///
    /// A provider's buy and sell rates for a pair are two rates, one each way. They are separate
    /// quotes, not reciprocals, so build each from its own quote rather than with ``inverted()``.
    ///
    /// ```swift
    /// let eurGbp = Rate(string: "0.87").flatMap(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>.init)
    /// ```
    struct ExchangeRateOf<From: CurrencyRepresentation, To: CurrencyRepresentation>: Sendable, Hashable
        where From.Mismatch == To.Mismatch
    {
        /// The rate in `To` minor units per one `From` minor unit, always greater than zero. It
        /// differs from the public per-major-unit quote only when the two currencies' scales differ.
        @usableFromInline let minorPerMinorRate: Rate

        /// What the rate carries to know the currency it converts from: nothing for a typed currency.
        @usableFromInline let fromStorage: From.Storage

        /// What the rate carries to know the currency it converts to: nothing for a typed currency.
        @usableFromInline let toStorage: To.Storage

        /// Creates a rate from a stored rate already known to be positive.
        ///
        /// - Parameters:
        ///   - rate: The rate in `To` minor units per one `From` minor unit, greater than zero.
        ///   - fromStorage: What names the currency the rate converts from.
        ///   - toStorage: What names the currency the rate converts to.
        @inlinable @inline(__always)
        init(unchecked rate: Rate, fromStorage: From.Storage, toStorage: To.Storage) {
            self.minorPerMinorRate = rate
            self.fromStorage = fromStorage
            self.toStorage = toStorage
        }

        /// Returns the customer rate for this mid-market rate: the rate less the provider's margin.
        ///
        /// The customer keeps the fraction of the mid rate the margin does not take, so the result is
        /// never larger than the mid rate. It keeps this rate's currencies, so it never throws
        /// ``FX/ExchangeError/currencyMismatch(_:)``.
        ///
        /// ```swift
        /// let mid = FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("1.5")!
        /// let margin = FX.Margin(.percent(20))!
        /// let customer = try mid.applyingMargin(margin)   // 1.2
        /// ```
        ///
        /// - Parameter margin: The provider's margin.
        /// - Returns: The mid rate less `margin`.
        /// - Throws: ``FX/ExchangeError/roundsToZero`` if the customer rate is too close to zero to
        ///   represent.
        @inlinable
        public func applyingMargin(_ margin: Margin) throws(ExchangeError<From.Mismatch>) -> Self {
            guard let customer = FX.customerRate(minorPerMinorRate, less: margin) else {
                throw .roundsToZero
            }

            return Self(unchecked: customer, fromStorage: fromStorage, toStorage: toStorage)
        }

        /// Returns the rate the other way round: how many major units of `From` one major unit of
        /// `To` buys.
        ///
        /// The inverse is rounded to the nearest representable rate, so inverting twice may not give
        /// back this rate exactly. It is never a provider's sell rate, which is a quote of its own.
        /// It swaps this rate's currencies, so it never throws ``FX/ExchangeError/currencyMismatch(_:)``.
        ///
        /// ```swift
        /// let eurGbp = FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.8")!
        /// let gbpEur = try eurGbp.inverted()   // 1.25
        /// ```
        ///
        /// - Returns: The inverse of this rate.
        /// - Throws: ``FX/ExchangeError/roundsToZero`` if the inverse is too close to zero to
        ///   represent.
        @inlinable
        public func inverted() throws(ExchangeError<From.Mismatch>) -> ExchangeRateOf<To, From> {
            guard let inverse = FX.inverse(of: minorPerMinorRate) else {
                throw .roundsToZero
            }

            return ExchangeRateOf<To, From>(unchecked: inverse, fromStorage: toStorage, toStorage: fromStorage)
        }
    }
}

public extension FX.ExchangeRateOf where From: CurrencyType, To: CurrencyType {
    /// Creates an exchange rate from a market quote: `To` major units per one `From` major unit.
    ///
    /// The quote is never rounded. Use ``init(string:)`` to learn why a quote was refused.
    ///
    /// ```swift
    /// FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.87")   // 0.87
    /// FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0")      // nil
    /// ```
    ///
    /// - Parameter marketRate: The market quote.
    /// - Returns: `nil` if the rate is not strictly positive (a zero or negative exchange rate
    ///   would zero or sign-flip a conversion), if it has more decimal places than a rate between
    ///   the two currencies holds, or if it is too large to hold.
    @inlinable
    init?(_ marketRate: Rate) {
        guard let rate = try? Self(marketRate: marketRate, fromStorage: .implied, toStorage: .implied) else {
            return nil
        }

        self = rate
    }

    /// Returns the rate that converts `From` all the way to `Onward`, via this rate and `other`.
    ///
    /// The shared currency is enforced by the types: this rate's `To` must be `other`'s `From`, so
    /// `EUR→GBP` is `EUR→USD` crossed with `USD→GBP`.
    ///
    /// ```swift
    /// let eurUsd = FX.ExchangeRateOf<Currencies.EUR, Currencies.USD>("1.1")!
    /// let usdGbp = FX.ExchangeRateOf<Currencies.USD, Currencies.GBP>("0.8")!
    /// let eurGbp = try eurUsd.crossed(with: usdGbp)   // 0.88
    /// ```
    ///
    /// - Parameter other: The rate from this rate's `To` currency onward.
    /// - Returns: The product of this rate and `other`.
    /// - Throws: ``FX/ExchangeError/overflow`` if the product is too large to represent;
    ///   ``FX/ExchangeError/roundsToZero`` if it is too close to zero to represent.
    @inlinable
    func crossed<Onward: CurrencyType>(
        with other: FX.ExchangeRateOf<To, Onward>
    ) throws(FX.ExchangeError<Never>) -> FX.ExchangeRateOf<From, Onward> {
        let composed = try FX.crossedRate(minorPerMinorRate, onward: other.minorPerMinorRate).get()

        return FX.ExchangeRateOf<From, Onward>(unchecked: composed, fromStorage: fromStorage, toStorage: other.toStorage)
    }
}

extension FX {
    /// Returns the customer rate for a mid rate: the fraction of it that a margin does not take.
    ///
    /// - Parameters:
    ///   - mid: A positive rate in smallest units of one currency per smallest unit of another.
    ///   - margin: The provider's margin.
    /// - Returns: `mid` less `margin`, or `nil` if that rounds to zero.
    @usableFromInline
    static func customerRate(_ mid: Rate, less margin: Margin) -> Rate? {
        // margin is in [0, 1), so the kept fraction is in (0, 1] and the product is no larger than
        // the rate: it can't overflow, only round to zero.
        guard let customer = mid.multiplied(by: margin.rate.subtracted(from: .par)), customer.isPositive else {
            return nil
        }

        return customer
    }

    /// Returns the inverse of a rate between smallest units.
    ///
    /// - Parameter rate: A positive rate in smallest units of one currency per smallest unit of
    ///   another.
    /// - Returns: The rate the other way round, rounded to the nearest representable rate, or `nil`
    ///   if that rounds to zero.
    @usableFromInline
    static func inverse(of rate: Rate) -> Rate? {
        // The inverse of `To` minor units per `From` minor unit is `From` per `To`, so it needs no
        // rescaling. A positive rate is at least 10⁻¹⁸, so the inverse is at most 10¹⁸ and the
        // divide can't overflow, only round to zero.
        let inverse = Rate(Rate.par.value / rate.value)

        return inverse.isPositive ? inverse : nil
    }

    /// Returns the product of two rates between smallest units that share a currency.
    ///
    /// - Parameters:
    ///   - rate: A positive rate into the shared currency.
    ///   - onward: A positive rate out of the shared currency.
    /// - Returns: The rate from `rate`'s first currency to `onward`'s second;
    ///   ``ExchangeError/overflow`` if the product is too large to represent;
    ///   ``ExchangeError/roundsToZero`` if it is too close to zero to represent.
    @usableFromInline
    static func crossedRate(_ rate: Rate, onward: Rate) -> Result<Rate, ExchangeError<Never>> {
        // Both are minor-per-minor, so the shared minor unit cancels and the product needs no scale
        // adjustment.
        guard let composed = rate.multiplied(by: onward) else {
            return .failure(.overflow)
        }
        guard composed.isPositive else {
            return .failure(.roundsToZero)
        }

        return .success(composed)
    }
}
