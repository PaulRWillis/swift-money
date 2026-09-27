import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// `CurrencyArrangement` is the interned cell CLDR's 2×2 (standard/accounting × glyph/letters) indexes
// into: a pattern plus the grouping sizes CLDR's own pattern carries alongside it. Value semantics only
// — the blob decoder and generator exercise the decoding/interning behaviour separately.
@Suite("Currency Arrangement Tests")
struct CurrencyArrangementTests {

    static let pattern = MoneyFormatPattern(
        positive: MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: []),
        negative: MoneyFormatAffixes(prefix: [.sign, .currency, .currencySpacing], suffix: []),
        accountingNegative: MoneyFormatAffixes(prefix: [.literal("("), .currency], suffix: [.literal(")")])
    )

    @Test("Two arrangements with the same pattern and sizes are equal")
    func equalArrangementsCompareEqual() {
        let first = CurrencyArrangement(pattern: Self.pattern, primaryGroupingSize: 3, secondaryGroupingSize: 3)
        let second = CurrencyArrangement(pattern: Self.pattern, primaryGroupingSize: 3, secondaryGroupingSize: 3)

        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
    }

    @Test("Arrangements differing only in secondary grouping size are not equal")
    func differingGroupingSizeCompareUnequal() {
        let uniform = CurrencyArrangement(pattern: Self.pattern, primaryGroupingSize: 3, secondaryGroupingSize: 3)
        let indian = CurrencyArrangement(pattern: Self.pattern, primaryGroupingSize: 3, secondaryGroupingSize: 2)

        #expect(uniform != indian)
    }

    @Test("The stored pattern and sizes are read back unchanged")
    func holdsThePatternAndSizes() {
        let arrangement = CurrencyArrangement(pattern: Self.pattern, primaryGroupingSize: 3, secondaryGroupingSize: 2)

        #expect(arrangement.pattern == Self.pattern)
        #expect(arrangement.primaryGroupingSize == 3)
        #expect(arrangement.secondaryGroupingSize == 2)
    }
}
