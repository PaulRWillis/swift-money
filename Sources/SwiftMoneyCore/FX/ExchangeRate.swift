public extension FX {
    /// An exchange rate between two currencies known only at runtime, such as a rate from a
    /// provider's feed for any of many pairs.
    ///
    /// The rate carries its pair as ``ExchangeRateOf/from`` and ``ExchangeRateOf/to``.
    ///
    /// ```swift
    /// let eurGbp = try FX.ExchangeRate(string: "0.87", from: .eur, to: .gbp)
    /// eurGbp.to            // GBP
    /// eurGbp.description   // "0.87"
    /// ```
    typealias ExchangeRate = ExchangeRateOf<AnyCurrency, AnyCurrency>
}

public extension FX.ExchangeRateOf where From == AnyCurrency, To == AnyCurrency {
    /// Creates an exchange rate between two currencies from a market quote: `to` major units per
    /// one `from` major unit.
    ///
    /// The quote is never rounded. Use ``init(string:from:to:)`` to learn why a quote was refused.
    ///
    /// ```swift
    /// FX.ExchangeRate("0.87", from: .eur, to: .gbp)   // 0.87
    /// FX.ExchangeRate("0", from: .eur, to: .gbp)      // nil
    /// ```
    ///
    /// - Parameters:
    ///   - marketRate: The market quote.
    ///   - from: The currency the rate converts from.
    ///   - to: The currency the rate converts to.
    /// - Returns: `nil` if the rate is not strictly positive, if it has more decimal places than a
    ///   rate between the two currencies holds, or if it is too large to hold.
    init?(_ marketRate: Rate, from: Currency, to: Currency) {
        guard let rate = try? Self(marketRate: marketRate, fromStorage: from, toStorage: to) else {
            return nil
        }

        self = rate
    }

    /// Creates an exchange rate between two currencies from a market quote's text: `to` major
    /// units per one `from` major unit, as a plain decimal.
    ///
    /// The quote is never rounded. A rate holds 18 decimal places of `to`'s smallest unit per
    /// `from`'s smallest unit, so how many places a quote may have depends on the two currencies.
    ///
    /// ```swift
    /// let eurGbp = try FX.ExchangeRate(string: "0.87", from: .eur, to: .gbp)
    /// let usdJpy = try FX.ExchangeRate(string: "149.5", from: .usd, to: .jpy)
    /// let tooFine = try FX.ExchangeRate(string: "149.12345678901234567", from: .usd, to: .jpy)   // throws
    /// ```
    ///
    /// - Parameters:
    ///   - quote: The market quote, such as `"0.87"`.
    ///   - from: The currency the rate converts from.
    ///   - to: The currency the rate converts to.
    /// - Throws: ``FX/ExchangeRateParsingError/unrecognizedText`` if `quote` is not a plain decimal;
    ///   ``FX/ExchangeRateParsingError/notPositive`` if it is zero or negative;
    ///   ``FX/ExchangeRateParsingError/inexactRate(maximumFractionDigits:)`` if it has more places
    ///   than the rate holds; ``FX/ExchangeRateParsingError/overflow`` if it is too large to hold.
    init(string quote: String, from: Currency, to: Currency) throws(FX.ExchangeRateParsingError) {
        try self.init(quote: quote, fromStorage: from, toStorage: to)
    }

    /// Returns the rate that converts ``ExchangeRateOf/from`` all the way to `other`'s
    /// ``ExchangeRateOf/to``, via this rate and `other`.
    ///
    /// `other` must start where this rate ends: `EUR→GBP` is `EUR→USD` crossed with `USD→GBP`. The
    /// currencies are checked before the rates are multiplied, so a pair that both mismatches and
    /// overflows reports the mismatch.
    ///
    /// ```swift
    /// let eurUsd = FX.ExchangeRate("1.1", from: .eur, to: .usd)!
    /// let usdGbp = FX.ExchangeRate("0.8", from: .usd, to: .gbp)!
    /// let eurGbp = try eurUsd.crossed(with: usdGbp)   // 0.88
    /// ```
    ///
    /// - Parameter other: The rate from this rate's ``ExchangeRateOf/to`` currency onward.
    /// - Returns: The product of this rate and `other`.
    /// - Throws: ``FX/ExchangeError/currencyMismatch(_:)`` with `other`'s ``ExchangeRateOf/from`` if
    ///   it is not this rate's ``ExchangeRateOf/to``; ``FX/ExchangeError/overflow`` if the product is
    ///   too large to represent; ``FX/ExchangeError/roundsToZero`` if it is too close to zero to
    ///   represent.
    func crossed(with other: FX.ExchangeRate) throws(FX.ExchangeError<Currency>) -> FX.ExchangeRate {
        guard toStorage == other.fromStorage else {
            try Self.mismatch(other.fromStorage)
        }

        switch FX.crossedRate(minorPerMinorRate, onward: other.minorPerMinorRate) {
        case let .success(composed):
            return Self(unchecked: composed, fromStorage: fromStorage, toStorage: other.toStorage)

        case .failure(.overflow):
            throw .overflow

        case .failure(.roundsToZero):
            throw .roundsToZero
        }
    }
}

extension FX.ExchangeRateOf where From == AnyCurrency, To == AnyCurrency {
    // Out of line so that crossing a matching pair, the common path, builds no error.
    /// Throws a currency mismatch.
    ///
    /// - Parameter currency: The currency the second rate converts from.
    /// - Throws: ``FX/ExchangeError/currencyMismatch(_:)`` with `currency`, always.
    @inline(never)
    private static func mismatch(_ currency: Currency) throws(FX.ExchangeError<Currency>) -> Never {
        throw .currencyMismatch(currency)
    }
}
