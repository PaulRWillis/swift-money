/// A typed exchange rate that converts between two currencies.
///
/// `ExchangeRate<From, To>` stores the rate as a `Rate` —
/// the ratio of target-currency minor units to source-currency minor units —
/// reduced to lowest terms using GCD.
///
/// The canonical way to construct a rate is with a minor-unit pair:
///
/// ```swift
/// // 1 EUR = 0.85 GBP → 100 EUR minor units correspond to 85 GBP minor units
/// let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)
/// ```
///
/// Because the pair is GCD-reduced at initialisation, rates with equivalent
/// ratios compare equal via `==`:
///
/// ```swift
/// ExchangeRate<EUR, GBP>(from: 200, to: 170)
///     == ExchangeRate<EUR, GBP>(from: 20, to: 17)  // true
/// ```
///
/// ## Conversion
///
/// ```swift
/// let eur10 = Money<EUR>(minorUnits: 1000)       // €10.00
/// let gbp   = rate.convert(eur10)                // £8.50
/// ```
///
/// Conversion delegates to ``Money/multiplied(by:rounding:)`` and inherits
/// its round-trip invariant and overflow trapping.
///
/// ## Encoding
///
/// `ExchangeRate` is `Codable` using a `fromMinorUnits` / `toMinorUnits`
/// JSON representation. The stored values are the GCD-reduced form:
///
/// ```json
/// {"fromMinorUnits": 20, "toMinorUnits": 17}
/// ```
public struct ExchangeRate<From: Currency, To: Currency>: Sendable {

    // MARK: - Storage

    /// The fractional multiplier applied to `From` minor units to produce `To` minor units.
    ///
    /// Numerator = `toMinorUnits`, denominator = `fromMinorUnits`, both GCD-reduced.
    public let rate: Rate

    // MARK: - Private designated initialiser

    /// Creates an `ExchangeRate` directly from a pre-validated `Rate`.
    /// The caller must have already checked that the rate's numerator is positive.
    private init(_uncheckedRate rate: Rate) {
        self.rate = rate
    }

    // MARK: - Minor-unit pair initialiser

    /// Creates an exchange rate from a minor-unit pair.
    ///
    /// The ratio `toMinorUnits / fromMinorUnits` defines the conversion factor. The
    /// pair is GCD-reduced immediately, so `init(from: 200, to: 170)` and
    /// `init(from: 20, to: 17)` produce equal values.
    ///
    /// Returns `nil` if either argument is ≤ 0.
    ///
    /// - Parameters:
    ///   - fromMinorUnits: A positive count of minor units of the source currency.
    ///   - toMinorUnits: The corresponding positive count of minor units of the target currency.
    public init?(from fromMinorUnits: Int64, to toMinorUnits: Int64) {
        guard fromMinorUnits > 0, toMinorUnits > 0 else { return nil }
        self.init(_uncheckedRate: Rate(_unchecked: toMinorUnits, denominator: fromMinorUnits))
    }

    // MARK: - Major-unit rate initialisers

    /// Creates an exchange rate from a major-unit rate expressed as a `Rate`.
    ///
    /// `majorUnitRate` expresses how many major units of `To` one major unit of `From`
    /// is worth — the standard presentation used by market data feeds (e.g. x-rates.com).
    /// For example, a GBP/JPY rate of 215.16 means £1 converts to 215.16 JPY, which
    /// expressed as a `Rate` is `21516/100` (or `5379/25` after reduction).
    ///
    /// Internally the rate is scaled by the `minimalQuantisation` of each currency to
    /// produce a minor-unit rate:
    ///
    /// ```
    /// minor-unit rate = majorUnitRate × (To.minimalQuantisation / From.minimalQuantisation)
    /// ```
    ///
    /// ```swift
    /// // 1 GBP = 215.16 JPY  (GBP minQ: 100, JPY minQ: 1)
    /// let rate = ExchangeRate<GBP, JPY>(
    ///     majorUnitRate: Rate(numerator: 21516, denominator: 100)!
    /// )
    /// rate?.convert(Money<GBP>(minorUnits: 100))  // 215 JPY (exact 215.16 rounds to 215)
    /// ```
    ///
    /// - Returns: `nil` if `majorUnitRate.numeratorValue ≤ 0`, or if scaling the rate by
    ///   the currency quantisations would overflow `Int64`.
    public init?(majorUnitRate: Rate) {
        guard majorUnitRate.numeratorValue > 0 else { return nil }
        let toMinQ   = To.minimalQuantisation.int64Value
        let fromMinQ = From.minimalQuantisation.int64Value
        // Scale: numerator × To.minQ, denominator × From.minQ
        let (scaledNumerator,   overflowN) = majorUnitRate.numeratorValue.multipliedReportingOverflow(by: toMinQ)
        guard !overflowN, scaledNumerator != .min else { return nil }
        let (scaledDenominator, overflowD) = majorUnitRate.denominatorValue.multipliedReportingOverflow(by: fromMinQ)
        guard !overflowD, scaledDenominator > 0 else { return nil }
        self.init(_uncheckedRate: Rate(_unchecked: scaledNumerator, denominator: scaledDenominator))
    }

    // MARK: - Derived values

    /// The source-currency side of the rate in lowest terms.
    ///
    /// Equal to `rate.denominatorValue`. May differ from the `fromMinorUnits`
    /// argument passed to `init` if GCD reduction was applied.
    public var fromMinorUnits: Int64 { rate.denominatorValue }

    /// The target-currency side of the rate in lowest terms.
    ///
    /// Equal to `rate.numeratorValue`. May differ from the `toMinorUnits`
    /// argument passed to `init` if GCD reduction was applied.
    public var toMinorUnits: Int64 { rate.numeratorValue }

    // MARK: - Conversion

    /// Converts a `Money<From>` amount to `Money<To>`, returning both the
    /// converted amount and the actual rate that was applied after rounding.
    ///
    /// Because money is stored as a discrete integer number of minor units,
    /// fractional multiplication may require rounding. The returned
    /// ``Conversion`` carries the rounded `converted` amount
    /// and the `effectiveRate` implied by that rounding, so callers can reconcile
    /// or audit the difference between the nominal and applied rate.
    ///
    /// ```swift
    /// let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
    /// let r = rate.conversionResult(of: Money<EUR>(minorUnits: 101))
    /// r.converted    // Money<GBP>(minorUnits: 86)
    /// r.effectiveRate   // ExchangeRate<EUR, GBP>(from: 101, to: 86)
    /// ```
    ///
    /// ``Conversion/effectiveRate`` is `nil` only when a
    /// non-zero input rounds down to zero (the amount is smaller than half a
    /// minor unit of `To` at this rate).
    ///
    /// - Parameters:
    ///   - money: The amount to convert. Must not be NaN.
    ///   - rounding: The rounding rule for fractional minor units.
    ///     Defaults to `.toNearestOrAwayFromZero`.
    /// - Returns: An ``Conversion`` with the converted amount
    ///   and actual rate.
    /// - Precondition: `money` must not be NaN.
    public func conversionResult(
        of money: Money<From>,
        rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> Conversion<From, To> {
        let r = money.multiplied(by: rate, rounding: rounding)
        let converted = Money<To>(_unchecked: r.result.minorUnits)
        // Wrap the Rate effectiveRate as a typed ExchangeRate.
        // effectiveRate.numeratorValue == 0 only when a non-zero input rounds to zero;
        // in that case there is no meaningful typed rate to return.
        let effectiveRate: ExchangeRate<From, To>? = r.effectiveRate.numeratorValue > 0
            ? ExchangeRate(_uncheckedRate: r.effectiveRate)
            : nil
        return Conversion(converted: converted, effectiveRate: effectiveRate)
    }

    /// Converts a `Money<From>` amount to `Money<To>` using this exchange rate.
    ///
    /// Delegates to ``conversionResult(of:rounding:)`` and returns only the
    /// converted amount. Use ``conversionResult(of:rounding:)`` directly when
    /// you also need the actual post-rounding rate.
    ///
    /// ```swift
    /// let rate = ExchangeRate<EUR, GBP>(from: 100, to: 85)!
    /// rate.convert(Money<EUR>(minorUnits: 1000))  // Money<GBP>(minorUnits: 850)
    /// ```
    ///
    /// - Parameters:
    ///   - money: The amount to convert. Must not be NaN.
    ///   - rounding: The rounding rule for fractional minor units.
    ///     Defaults to `.toNearestOrAwayFromZero`.
    /// - Returns: The converted amount expressed in `To`.
    /// - Precondition: `money` must not be NaN.
    public func convert(
        _ money: Money<From>,
        rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> Money<To> {
        conversionResult(of: money, rounding: rounding).converted
    }
}

// MARK: - Equatable

extension ExchangeRate: Equatable {
    public static func == (lhs: ExchangeRate, rhs: ExchangeRate) -> Bool {
        lhs.rate == rhs.rate
    }
}

// MARK: - Hashable

extension ExchangeRate: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rate)
    }
}

// MARK: - Codable

extension ExchangeRate: Codable {

    private enum CodingKeys: String, CodingKey {
        case fromMinorUnits
        case toMinorUnits
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let from = try container.decode(Int64.self, forKey: .fromMinorUnits)
        let to   = try container.decode(Int64.self, forKey: .toMinorUnits)
        guard from > 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .fromMinorUnits, in: container,
                debugDescription: "ExchangeRate fromMinorUnits must be positive"
            )
        }
        guard to > 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .toMinorUnits, in: container,
                debugDescription: "ExchangeRate toMinorUnits must be positive"
            )
        }
        self.init(_uncheckedRate: Rate(_unchecked: to, denominator: from))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fromMinorUnits, forKey: .fromMinorUnits)
        try container.encode(toMinorUnits,   forKey: .toMinorUnits)
    }
}

