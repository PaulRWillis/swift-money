// MARK: - CustomStringConvertible

extension Money: CustomStringConvertible {
    public var description: String {
        self.formatted()
    }
}

// MARK: - CustomDebugStringConvertible

extension Money: CustomDebugStringConvertible {
    /// A debug-friendly representation showing the currency type, raw minor
    /// units, and formatted value.
    ///
    /// ```swift
    /// Money<GBP>(minorUnits: 150).debugDescription
    /// // "Money<GBP>(minorUnits: 150) — \"£1.50\""
    /// ```
    public var debugDescription: String {
        if isNaN {
            return "Money<\(Currency.code)>(NaN)"
        }
        return "Money<\(Currency.code)>(minorUnits: \(_storage)) — \"\(formatted())\""
    }
}
