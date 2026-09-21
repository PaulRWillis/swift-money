/// The text a locale writes before and after the digits of an amount, for one sign of one amount.
///
/// The digits, the decimal separator and the fraction are the body between the two: they are always
/// present and always in that order, so they are not tokens. Everything a locale arranges around them
/// — the sign, the currency, the spacing, any literal — is a token in ``prefix`` or ``suffix``. An
/// empty affix is normal; most suffixes are empty.
///
/// ```swift
/// // "¤#,##0.00": currency and spacing lead, nothing trails.
/// MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: [])
/// // "#,##0.00 ¤": nothing leads but the sign, spacing and currency trail.
/// MoneyFormatAffixes(prefix: [.sign], suffix: [.currencySpacing, .currency])
/// ```
@usableFromInline
package struct MoneyFormatAffixes: Equatable, Hashable, Sendable {
    /// The tokens written before the digits.
    @usableFromInline
    package let prefix: [MoneyFormatToken]

    /// The tokens written after the digits.
    @usableFromInline
    package let suffix: [MoneyFormatToken]

    package init(prefix: [MoneyFormatToken], suffix: [MoneyFormatToken]) {
        self.prefix = prefix
        self.suffix = suffix
    }
}
