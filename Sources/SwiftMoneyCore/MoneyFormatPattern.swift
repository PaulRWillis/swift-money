/// How a locale lays out an amount, as CLDR's currency patterns describe it: one arrangement of affixes
/// for a positive amount and one for a negative, plus the arrangement the accounting form uses.
///
/// ```swift
/// // "¤#,##0.00" with "(¤#,##0.00)" for accounting, as English writes it.
/// MoneyFormatPattern(
///     positive: MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: []),
///     negative: MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: []),
///     accountingNegative: MoneyFormatAffixes(
///         prefix: [.literal("("), .currency, .currencySpacing], suffix: [.literal(")")]
///     )
/// )
/// ```
///
/// A pattern holds no text of its own beyond its literals, so every currency in a locale shares one.
@usableFromInline
package struct MoneyFormatPattern: Equatable, Hashable, Sendable {
    @usableFromInline
    package let positive: MoneyFormatAffixes

    @usableFromInline
    package let negative: MoneyFormatAffixes

    /// The arrangement for a negative amount under the accounting sign strategy: parentheses in most
    /// locales, a plain minus in the rest.
    @usableFromInline
    package let accountingNegative: MoneyFormatAffixes

    package init(
        positive: MoneyFormatAffixes,
        negative: MoneyFormatAffixes,
        accountingNegative: MoneyFormatAffixes
    ) {
        self.positive = positive
        self.negative = negative
        self.accountingNegative = accountingNegative
    }

    /// The arrangement for one amount under one sign strategy.
    ///
    /// A shown sign takes the slot CLDR gives the minus, which the negative arrangement carries, so a
    /// forced plus lays out like a minus would. When no sign shows, the plain positive arrangement is
    /// used whatever the amount's own sign.
    @usableFromInline
    package func affixes(for amountSign: Sign, sign: MoneyFormatOptions.Sign) -> MoneyFormatAffixes {
        switch sign {
        case .never:
            return positive
        case .always:
            return negative
        case .accounting:
            return amountSign == .negative ? accountingNegative : positive
        case .automatic:
            return amountSign == .negative ? negative : positive
        }
    }
}
