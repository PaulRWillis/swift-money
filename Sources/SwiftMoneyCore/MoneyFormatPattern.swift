/// How a locale lays out an amount, as CLDR's currency patterns describe it: one arrangement for a
/// positive amount and one for a negative, plus the arrangement the accounting form uses.
///
/// ```swift
/// // "¤#,##0.00" with "(¤#,##0.00)" for accounting, as English writes it
/// MoneyFormatPattern(
///     positive: [.currency, .currencyGap, .integerDigits, .decimalSeparator, .fractionDigits],
///     negative: [.sign, .currency, .currencyGap, .integerDigits, .decimalSeparator, .fractionDigits],
///     accountingNegative: [.literal("("), .currency, .currencyGap, .integerDigits, .decimalSeparator, .fractionDigits, .literal(")")]
/// )
/// ```
///
/// A pattern holds no text of its own beyond its literals, so every currency in a locale shares one.
@usableFromInline
package struct MoneyFormatPattern: Equatable, Hashable, Sendable {
    @usableFromInline
    package let positive: [MoneyFormatPart]

    @usableFromInline
    package let negative: [MoneyFormatPart]

    /// The arrangement for a negative amount under the accounting sign strategy: parentheses in most
    /// locales, a plain minus in the rest.
    @usableFromInline
    package let accountingNegative: [MoneyFormatPart]

    package init(
        positive: [MoneyFormatPart],
        negative: [MoneyFormatPart],
        accountingNegative: [MoneyFormatPart]
    ) {
        self.positive = positive
        self.negative = negative
        self.accountingNegative = accountingNegative
    }

    /// The arrangement for one amount under one sign strategy.
    @usableFromInline
    package func parts(negative isNegative: Bool, sign: MoneyFormatOptions.Sign) -> [MoneyFormatPart] {
        guard isNegative else {
            return positive
        }

        return sign == .accounting ? accountingNegative : negative
    }
}
