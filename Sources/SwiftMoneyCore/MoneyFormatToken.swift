/// One piece of the text a locale writes around the digits of an amount, in the order it writes them.
///
/// A token says *what* goes there, never what it reads: the sign, currency and spacing it stands for
/// come from the ``MoneyFormat`` being rendered. So one list of tokens describes a locale's layout for
/// every currency, and a currency only supplies its own symbol and spacing. The digits themselves are
/// not tokens; they are the body a ``MoneyFormatAffixes`` wraps.
@usableFromInline
package enum MoneyFormatToken: Equatable, Hashable, Sendable {
    /// The sign, or nothing, as the display options decide.
    case sign

    /// The currency, however this format names it.
    case currency

    /// What separates the currency from the digits.
    case currencySpacing

    /// Text the locale's pattern writes literally, such as an accounting parenthesis or Romanian's
    /// "de" between an amount and a currency's name.
    case literal(String)
}
