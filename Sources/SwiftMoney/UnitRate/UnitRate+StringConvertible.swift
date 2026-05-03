// MARK: - CustomStringConvertible

#if canImport(Foundation)
import Foundation

extension UnitRate: CustomStringConvertible where U: CustomStringConvertible {
    /// The unit rate formatted as a localised currency string.
    ///
    /// ```swift
    /// let oilPrice = UnitRate<USD, String>(Rate("14500/200")!, per: "barrel")
    /// oilPrice.description   // "$72.50/barrel"
    /// ```
    public var description: String {
        formatted()
    }
}
#else
extension UnitRate: CustomStringConvertible where U: CustomStringConvertible {
    public var description: String {
        "\(rate) / \(unit)"
    }
}
#endif

// MARK: - CustomDebugStringConvertible

extension UnitRate: CustomDebugStringConvertible where U: CustomStringConvertible {
    /// A debug-friendly representation showing the generic parameters,
    /// rate, and unit.
    ///
    /// ```swift
    /// let rate = UnitRate<GBP, String>(Rate("23/1000000")!, per: "kWh")
    /// rate.debugDescription
    /// // "UnitRate<GBP, String>(rate: 23/1000000, per: \"kWh\")"
    /// ```
    public var debugDescription: String {
        "UnitRate<\(C.code), \(U.self)>(rate: \(rate), per: \"\(unit)\")"
    }
}
