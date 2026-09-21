/// One piece of a rendered amount, in the order a locale writes them.
///
/// A part says *what* goes there, never what it reads: the text each one stands for comes from the
/// ``MoneyFormat`` being rendered, or from the amount itself. So one list of parts describes a
/// locale's layout for every currency, and a currency only supplies its own symbol and gap.
@usableFromInline
package enum MoneyFormatPart: Equatable, Hashable, Sendable {
    /// The sign, or nothing, as the display options decide.
    case sign

    /// The currency, however this format names it.
    case currency

    /// What separates the currency from the digits.
    case currencyGap

    /// The whole digits, with the format's grouping separators written between groups.
    case integerDigits

    /// What separates the whole digits from the fraction digits.
    case decimalSeparator

    /// The fraction digits.
    case fractionDigits

    /// Text the locale's pattern writes literally, such as an accounting parenthesis.
    case literal(String)
}
