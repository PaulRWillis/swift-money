/// What a decoded payload named as an amount's currency: nothing, a code alone, or a code together
/// with a scale read as a separate field.
///
/// A closed alternative rather than two independent optional parameters. Two optionals let a caller
/// pass a code with no scale in two different-looking ways that mean different things (scale `nil`
/// versus scale omitted are indistinguishable, yet "no scale" can silently mean "look this up as an
/// ISO currency instead"), and let a caller pass a scale with no code, which names no currency.
/// This type only has the three combinations that name one or none, so there is no fourth shape
/// to guard against.
public enum CurrencyField: Equatable, Hashable, Sendable {
    /// Nothing named a currency.
    case none

    /// A code alone, with no scale on the wire: either a currency this library's own ISO table
    /// resolves from the code by itself, or a code a fixed-currency representation can check
    /// against its own without needing anything else.
    case code(CurrencyCode)

    /// A code and a scale, read as separate fields: what a currency the ISO table does not ship
    /// needs to be rebuilt from, and what any other currency is checked against. `rawScale` is
    /// exactly what was on the wire, not yet checked against ``UnitScale``'s range.
    case custom(code: CurrencyCode, rawScale: Int)
}

extension CurrencyField {
    /// Builds the field a decoder actually found, from the two independent values it read: `.none`
    /// when no code arrived, whatever the scale, `.code` when a code arrived with no scale, `.custom`
    /// when both did.
    package init(code: CurrencyCode?, rawScale: Int?) {
        switch (code, rawScale) {
        case (nil, _):
            self = .none
        case let (code?, nil):
            self = .code(code)
        case let (code?, rawScale?):
            self = .custom(code: code, rawScale: rawScale)
        }
    }
}
