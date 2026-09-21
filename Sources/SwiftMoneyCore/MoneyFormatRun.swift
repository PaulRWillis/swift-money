/// One run of a rendered amount: a piece of text together with what it represents.
///
/// ``MoneyFormat/format(_:)`` fuses an amount into a single string; ``MoneyFormat/runs(_:options:)``
/// keeps the pieces apart instead, so a caller can treat each differently — tagging them for an
/// `AttributedString`, say. The text is identical either way: concatenating a run list gives the same
/// string ``MoneyFormat/format(_:)`` returns. Grouping separators are their own runs, interleaved
/// between the integer-digit runs they divide.
@usableFromInline
package enum MoneyFormatRun: Equatable, Sendable {
    /// The sign glyph, present only when one is written.
    case sign(String)

    /// The currency, however this format names it.
    case currency(String)

    /// The spacing between the currency and the digits.
    case currencySpacing(String)

    /// Text the locale's pattern writes literally, such as an accounting parenthesis or a word
    /// between the amount and a currency's name.
    case literal(String)

    /// A run of whole digits, with no separator inside it.
    case integerDigits(String)

    /// One grouping separator, between two ``integerDigits`` runs.
    case groupingSeparator(String)

    /// The separator between the whole digits and the fraction.
    case decimalSeparator(String)

    /// The fraction digits.
    case fractionDigits(String)

    /// The run's text, whatever it represents.
    @usableFromInline
    package var text: String {
        switch self {
        case .sign(let text), .currency(let text), .currencySpacing(let text), .literal(let text),
             .integerDigits(let text), .groupingSeparator(let text), .decimalSeparator(let text),
             .fractionDigits(let text):
            text
        }
    }
}
