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

extension MoneyBag: CustomStringConvertible {
    /// A human-readable representation of all accumulated amounts.
    ///
    /// Equivalent to ``formatted()``.
    public var description: String {
        formatted()
    }
}

extension MoneyBag: CustomDebugStringConvertible {
    /// A debug-friendly representation listing each currency and its raw minor
    /// units alongside the formatted string.
    ///
    /// ```swift
    /// var bag = MoneyBag()
    /// bag.add(Money<GBP>(minorUnits: 150))
    /// bag.debugDescription
    /// // "MoneyBag([GBP: 150]) — \"£1.50\""
    /// ```
    public var debugDescription: String {
        let entries = breakdown
            .map { "\($0.currencyCode): \($0.minorUnits)" }
            .joined(separator: ", ")
        return "MoneyBag([\(entries)]) — \"\(formatted())\""
    }
}
