import Testing
import SwiftMoney

@Suite("AnyMoney – Comparison and Ordering")
struct AnyMoney_ComparisonTests {

    // MARK: - Equatable

    @Test("Same currency and amount are equal")
    func equalSameCurrencyAndAmount() {
        let money1 = Money<TST_100>(minorUnits: 500).erased
        let money2 = Money<TST_100>(minorUnits: 500).erased
        #expect(money1 == money2)
    }

    @Test("Same currency, different amount are not equal")
    func notEqualDifferentAmount() {
        let money1 = Money<TST_100>(minorUnits: 100).erased
        let money2 = Money<TST_100>(minorUnits: 200).erased
        #expect(money1 != money2)
    }

    @Test("Different currency are not equal even with same minorUnits")
    func notEqualDifferentCurrency() {
        let money1 = Money<TST_100>(minorUnits: 100).erased
        let money2 = Money<TST_1>(minorUnits: 100).erased
        #expect(money1 != money2)
    }

    @Test("NaN equals NaN (sentinel semantics, not IEEE 754)")
    func nanEqualsSelf() {
        let nan1 = Money<TST_100>.nan.erased
        let nan2 = Money<TST_100>.nan.erased
        #expect(nan1 == nan2)
    }

    @Test("NaN is not equal to zero")
    func nanNotEqualToZero() {
        #expect(Money<TST_100>.nan.erased != Money<TST_100>.zero.erased)
    }

    // MARK: - Hashable

    @Test("Equal values produce equal hashes")
    func equalValuesHaveEqualHashes() {
        let money1 = Money<TST_100>(minorUnits: 12345).erased
        let money2 = Money<TST_100>(minorUnits: 12345).erased
        #expect(money1.hashValue == money2.hashValue)
    }

    @Test("Can be stored in a Set, deduplicating equal values")
    func hashableInSet() {
        let money1 = Money<TST_100>(minorUnits: 100).erased
        let money2 = Money<TST_100>(minorUnits: 200).erased
        let set: Set<AnyMoney> = [money1, money2, money1]
        #expect(set.count == 2)
    }

    @Test("Can be used as a Dictionary key")
    func hashableAsDictionaryKey() {
        let key = Money<TST_100>(minorUnits: 9995).erased
        var dict: [AnyMoney: String] = [:]
        dict[key] = "value"
        #expect(dict[key] == "value")
    }

    @Test("Different currencies with same minorUnits produce different Set entries")
    func differentCurrenciesDistinctInSet() {
        let money1 = Money<TST_100>(minorUnits: 100).erased
        let money2 = Money<TST_1>(minorUnits: 100).erased
        let set: Set<AnyMoney> = [money1, money2]
        #expect(set.count == 2)
    }

    // MARK: - Comparable — same currency

    @Test("Less than within same currency")
    func lessThanSameCurrency() {
        let small = Money<TST_100>(minorUnits: 10).erased
        let large = Money<TST_100>(minorUnits: 20).erased
        #expect(small < large)
        #expect(!(large < small))
    }

    @Test("Equal values are not less than each other")
    func equalValuesNotLessThan() {
        let money1 = Money<TST_100>(minorUnits: 10).erased
        let money2 = Money<TST_100>(minorUnits: 10).erased
        #expect(!(money1 < money2))
        #expect(!(money2 < money1))
    }

    @Test("Negative values sort before positive within same currency")
    func negativeBeforePositiveSameCurrency() {
        let neg = Money<TST_100>(minorUnits: -5).erased
        let pos = Money<TST_100>(minorUnits: 5).erased
        #expect(neg < pos)
    }

    @Test("NaN sorts before all non-NaN values within same currency")
    func nanSortsFirstSameCurrency() {
        let nan = Money<TST_100>.nan.erased
        let zero = Money<TST_100>.zero.erased
        let positive = Money<TST_100>(minorUnits: 1).erased
        #expect(nan < zero)
        #expect(nan < positive)
    }

    // MARK: - Comparable — cross-currency total order

    @Test("Cross-currency order is determined by currencyCode lexicographically")
    func crossCurrencyOrderByCurrencyCode() {
        // "TST_1" < "TST_100": both share "TST_1", then "TST_1" ends while
        // "TST_100" continues with "0" — the shorter string compares as lesser.
        let tst1 = Money<TST_1>(minorUnits: 1).erased
        let tst100 = Money<TST_100>(minorUnits: 9999).erased
        #expect(tst1 < tst100)
    }

    @Test("sorted() on a mixed-currency array is deterministic")
    func sortedMixedCurrencyIsDeterministic() {
        let values: [AnyMoney] = [
            Money<TST_1>(minorUnits: 30).erased,
            Money<TST_100>(minorUnits: 10).erased,
            Money<TST_1>(minorUnits: 10).erased,
            Money<TST_100>(minorUnits: 30).erased,
            Money<TST_100>(minorUnits: 20).erased,
            Money<TST_1>(minorUnits: 20).erased,
        ]
        let sorted = values.sorted()
        // "TST_1" < "TST_100" lexicographically, so TST_1 entries come first
        let expectedCurrençyCodes = ["TST_1", "TST_1", "TST_1", "TST_100", "TST_100", "TST_100"]
        let expectedMinorUnits: [Int64] = [10, 20, 30, 10, 20, 30]
        #expect(sorted.map { String($0.currencyCode) } == expectedCurrençyCodes)
        #expect(sorted.map(\.minorUnits) == expectedMinorUnits)
    }

    @Test("sorted() result is stable across multiple calls")
    func sortedIsStable() {
        let values: [AnyMoney] = [
            Money<TST_1>(minorUnits: 5).erased,
            Money<TST_100>(minorUnits: 5).erased,
        ]
        #expect(values.sorted() == values.sorted())
    }
}
