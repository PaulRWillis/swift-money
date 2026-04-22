// MARK: - CustomStringConvertible

extension AnyMoney: CustomStringConvertible {
    /// A human-readable currency string for this value.
    ///
    /// Equivalent to ``formatted()``.
    public var description: String {
        formatted()
    }
}

// MARK: - CustomDebugStringConvertible

extension AnyMoney: CustomDebugStringConvertible {
    /// A debug-friendly representation showing the currency code, raw minor
    /// units, and formatted value.
    ///
    /// ```swift
    /// Money<GBP>(minorUnits: 150).erased.debugDescription
    /// // "AnyMoney(GBP, minorUnits: 150) — \"£1.50\""
    /// ```
    public var debugDescription: String {
        if minorUnits == .min {
            return "AnyMoney(\(currencyCode), NaN)"
        }
        return "AnyMoney(\(currencyCode), minorUnits: \(minorUnits)) — \"\(formatted())\""
    }
}
