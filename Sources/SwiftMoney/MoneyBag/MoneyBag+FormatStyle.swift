import Foundation

extension MoneyBag {
    /// Formats all accumulated amounts as a single localised string.
    ///
    /// Each entry in `breakdown` (sorted by currency code) is formatted
    /// using its currency's symbol and minor-unit scale, then the results
    /// are joined with `", "`.
    ///
    /// ```swift
    /// var bag = MoneyBag()
    /// bag.add(Money<GBP>(minorUnits: 500))   // £5.00
    /// bag.add(Money<EUR>(minorUnits: 1000))  // €10.00
    ///
    /// bag.formatted()  // "€10.00, £5.00"   (sorted by currency code)
    /// bag.formatted(locale: Locale(identifier: "fr"))  // "10,00 €, 5,00 £GB"
    /// ```
    ///
    /// An empty bag returns an empty string.
    ///
    /// - Parameter locale: The locale used to format each amount.
    ///   Defaults to `.autoupdatingCurrent`.
    public func formatted(locale: Locale = .autoupdatingCurrent) -> String {
        let style = AnyMoney.FormatStyle(locale: locale)
        return breakdown.map { $0.formatted(style) }.joined(separator: ", ")
    }
}


