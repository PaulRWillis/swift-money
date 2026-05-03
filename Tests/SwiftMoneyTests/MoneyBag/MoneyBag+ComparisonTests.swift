import Testing
import SwiftMoney

@Suite("MoneyBag – Equatable & Hashable")
struct MoneyBag_EquatableTests {

    // MARK: - Equatable: empty

    @Test("Two empty bags are equal")
    func emptyBagsAreEqual() {
        #expect(MoneyBag() == MoneyBag())
    }

    // MARK: - Equatable: single currency

    @Test("Bags with the same single currency and amount are equal")
    func sameSingleCurrencyAreEqual() {
        let bag1 = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let bag2 = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        #expect(bag1 == bag2)
    }

    @Test("Bags with the same currency but different amounts are not equal")
    func differentAmountsNotEqual() {
        let bag1 = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let bag2 = MoneyBag().adding(Money<TST_100>(minorUnits: 499))
        #expect(bag1 != bag2)
    }

    @Test("Bag with one currency is not equal to bag with a different currency, same minor units")
    func differentCurrenciesNotEqual() {
        let bag1 = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let bag2 = MoneyBag().adding(Money<TST_1>(minorUnits: 500))
        #expect(bag1 != bag2)
    }

    // MARK: - Equatable: order independence

    @Test("Equality is independent of the order currencies were added")
    func orderIndependentEquality() {
        let bag1 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 900))
        let bag2 = MoneyBag()
            .adding(Money<TST_1>(minorUnits: 900))
            .adding(Money<TST_100>(minorUnits: 300))
        #expect(bag1 == bag2)
    }

    // MARK: - Equatable: zero entries

    @Test("Bag with a zero entry is not equal to an empty bag")
    func zeroEntryNotEqualToEmpty() {
        let withZero = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .subtracting(Money<TST_100>(minorUnits: 500))
        #expect(withZero != MoneyBag())
    }

    @Test("Two bags each with the same zero entry are equal")
    func twoZeroEntriesAreEqual() {
        let bag1 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .subtracting(Money<TST_100>(minorUnits: 500))
        let bag2 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 200))
            .subtracting(Money<TST_100>(minorUnits: 200))
        #expect(bag1 == bag2)
    }

    // MARK: - Equatable: multi-currency

    @Test("Bags with the same multiple currencies and amounts are equal")
    func multiCurrencyEqual() {
        let bag1 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 900))
            .adding(Money<TST_100_000_000>(minorUnits: 100))
        let bag2 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 900))
            .adding(Money<TST_100_000_000>(minorUnits: 100))
        #expect(bag1 == bag2)
    }

    @Test("Bags with the same currencies but one entry differs are not equal")
    func multiCurrencyOneEntryDiffers() {
        let bag1 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 900))
        let bag2 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 901))
        #expect(bag1 != bag2)
    }

    @Test("Bags with different currency counts are not equal")
    func differentCurrencyCountsNotEqual() {
        let bag1 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 900))
        let bag2 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
        #expect(bag1 != bag2)
    }

    // MARK: - Hashable: contract

    @Test("Equal bags produce the same hash value")
    func equalBagsSameHash() {
        let bag1 = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 300))
            .adding(Money<TST_1>(minorUnits: 900))
        let bag2 = MoneyBag()
            .adding(Money<TST_1>(minorUnits: 900))
            .adding(Money<TST_100>(minorUnits: 300))
        #expect(bag1 == bag2)
        #expect(bag1.hashValue == bag2.hashValue)
    }

    // MARK: - Hashable: Set usage

    @Test("MoneyBag can be used as a Set element — deduplicates equal bags")
    func usableInSet() {
        let bag1 = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let bag2 = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let bag3 = MoneyBag().adding(Money<TST_100>(minorUnits: 999))
        let set: Set<MoneyBag> = [bag1, bag2, bag3]
        #expect(set.count == 2)
    }

    @Test("MoneyBag can be used as a Dictionary key")
    func usableAsDictionaryKey() {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        var dict: [MoneyBag: String] = [:]
        dict[bag] = "value"
        #expect(dict[bag] == "value")
        #expect(dict[MoneyBag().adding(Money<TST_100>(minorUnits: 500))] == "value")
    }
}
