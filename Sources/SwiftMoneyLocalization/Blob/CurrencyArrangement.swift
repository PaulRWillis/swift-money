import SwiftMoneyCore

/// One CLDR-published cell of a locale's currency layout: the affix pattern beside the grouping sizes
/// its own subpattern carries. CLDR's number-format data gives a 2×2 of these — `standard`/`accounting`
/// crossed with the glyph/letter-adjacent symbol form — and this is the shared shape that cell takes,
/// whichever axis of the 2×2 it fills.
///
/// It carries the pattern and grouping *sizes* only, not the group separator or minimum grouping
/// digits: those come from the locale's numbering system, are shared across every arrangement a locale
/// holds, and would defeat interning if folded in (few distinct arrangements repeat across all
/// locales; a separator would make almost every one distinct).
package struct CurrencyArrangement: Equatable, Hashable, Sendable {
    /// The side the currency sits on, and the affixes for a positive, negative and accounting-negative
    /// amount.
    package let pattern: MoneyFormatPattern

    /// The size of the rightmost digit group.
    package let primaryGroupingSize: GroupingSize

    /// The size of every digit group above the rightmost, which differs from ``primaryGroupingSize``
    /// only in a locale that groups unevenly (India's `12,34,567`).
    package let secondaryGroupingSize: GroupingSize

    package init(
        pattern: MoneyFormatPattern,
        primaryGroupingSize: GroupingSize,
        secondaryGroupingSize: GroupingSize
    ) {
        self.pattern = pattern
        self.primaryGroupingSize = primaryGroupingSize
        self.secondaryGroupingSize = secondaryGroupingSize
    }
}
