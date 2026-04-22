import Foundation

extension AnyMoney {
    /// Formats this value as a localized currency string using the
    /// system's current locale.
    ///
    /// Uses the stored ``currencyCode`` and ``minorUnitRatio`` to produce
    /// output equivalent to `Money<C>.formatted()` for the same value,
    /// without requiring the currency metatype to be present.
    ///
    /// ```swift
    /// Money<GBP>(minorUnits: 150).erased.formatted()  // "£1.50"
    /// Money<EUR>(minorUnits: 150).erased.formatted()  // "€1.50"
    /// Money<JPY>(minorUnits: 500).erased.formatted()  // "JP¥500"
    /// ```
    public func formatted() -> String {
        minorUnits.formatted(
            .currency(code: currencyCode.stringValue)
            .scale(1.0 / Double(minimalQuantisation.int64Value))
        )
    }
}

extension AnyMoney: CustomStringConvertible {
    /// A human-readable currency string for this value.
    ///
    /// Equivalent to ``formatted()``.
    public var description: String {
        formatted()
    }
}
