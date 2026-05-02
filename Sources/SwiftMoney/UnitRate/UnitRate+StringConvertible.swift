// MARK: - CustomStringConvertible

extension UnitRate: CustomStringConvertible where U: CustomStringConvertible {
    /// The unit rate as a string in the form `"rate / unit"`.
    ///
    /// ```swift
    /// let oilPrice = UnitRate<USD, String>(Rate("14500/200")!, per: "barrel")
    /// oilPrice.description   // "145/2 / barrel"
    /// ```
    public var description: String {
        "\(rate) / \(unit)"
    }
}

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
