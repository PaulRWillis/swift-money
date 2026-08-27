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
}
