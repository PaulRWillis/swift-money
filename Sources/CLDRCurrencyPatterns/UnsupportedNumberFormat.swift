/// Something in a locale's number format that the generated tables cannot represent.
///
/// These are read before the pattern itself, because the pattern reader answers a narrower question
/// and would pass over them without noticing: it looks only between the currency placeholder and the
/// nearest digit.
public enum UnsupportedNumberFormat: Equatable, Sendable {
    /// The locale writes amounts in digits other than `0` to `9`, as Arabic-Indic and Devanagari do.
    case nonLatinDigits(numberingSystem: String)
}

extension UnsupportedNumberFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nonLatinDigits(let numberingSystem):
            "amounts are written in the \(numberingSystem) digits rather than 0 to 9"
        }
    }
}
