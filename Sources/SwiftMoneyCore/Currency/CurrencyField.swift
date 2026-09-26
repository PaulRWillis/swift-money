/// What a decoded payload named as an amount's currency: nothing, a code alone, or a code together
/// with a scale read as a separate field.
///
/// A closed alternative rather than two independent optional parameters. Two optionals let a caller
/// pass a code with no scale in two different-looking ways that mean different things (scale `nil`
/// versus scale omitted are indistinguishable, yet "no scale" can silently mean "look this up as an
/// ISO currency instead"), and let a caller pass a scale with no code, which is never meaningful.
/// This type only has the three combinations that ever matter, so there is no fourth, nonsensical
/// shape to guard against.
///
/// Whether the scale in ``custom(code:rawScale:)`` is even looked at is up to the representation
/// reading it: one whose currency is fixed at compile time (a `CurrencyType`) never needs a scale and
/// never inspects this one, so a malformed scale on such a payload cannot break a decode it has no
/// bearing on.
public enum CurrencyField: Equatable, Hashable, Sendable {
    /// Nothing named a currency.
    case none

    /// A code alone, with no scale on the wire: either a currency this library's own ISO table
    /// resolves from the code by itself, or a code a fixed-currency representation can check
    /// against its own without needing anything else.
    case code(CurrencyCode)

    /// A code and a scale, read as separate fields: what a currency the ISO table does not ship
    /// needs to be rebuilt from. `rawScale` is exactly what was on the wire, not yet checked against
    /// ``UnitScale``'s own range — validating it is the job of whichever representation actually
    /// consults it.
    case custom(code: CurrencyCode, rawScale: Int)
}

extension CurrencyField {
    /// Builds the field a decoder actually found, from the two independent values it read: `.none`
    /// when nothing named a currency, `.code` when a code arrived with no scale, `.custom` when both
    /// did.
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
