// MARK: - CustomStringConvertible

extension MoneyBag: CustomStringConvertible {
    /// A human-readable representation of all accumulated amounts.
    ///
    /// Equivalent to ``formatted()``.
    public var description: String {
        formatted()
    }
}

// MARK: - CustomDebugStringConvertible

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
