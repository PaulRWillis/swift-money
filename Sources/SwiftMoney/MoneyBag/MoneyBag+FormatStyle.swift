import Foundation

extension MoneyBag {
    /// Formats all accumulated amounts as a single localized string.
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
    /// ```
    ///
    /// An empty bag returns an empty string.
    public func formatted() -> String {
        breakdown.map { $0.formatted() }.joined(separator: ", ")
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
