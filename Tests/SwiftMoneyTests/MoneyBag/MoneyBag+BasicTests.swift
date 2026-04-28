import Testing
import SwiftMoney

@Suite("MoneyBag – Basic Properties")
struct MoneyBag_BasicTests {

    // MARK: - Empty bag

    @Test("isEmpty is true on a new empty bag")
    func isEmptyOnNew() {
        let bag = MoneyBag()
        #expect(bag.isEmpty)
    }

    @Test("currencyCodes is empty on a new bag")
    func currencyCodesEmptyOnNew() {
        let bag = MoneyBag()
        #expect(bag.currencyCodes.isEmpty)
    }

    @Test("balances is empty on a new bag")
    func breakdownEmptyOnNew() {
        let bag = MoneyBag()
        #expect(bag.balances.isEmpty)
    }

    @Test("balance(of:) returns nil for absent currency on empty bag")
    func amountNilOnEmpty() {
        let bag = MoneyBag()
        #expect(bag.balance(of: TST_100.self) == nil)
    }

    @Test("contains returns false for absent currency on empty bag")
    func containsFalseOnEmpty() {
        let bag = MoneyBag()
        #expect(!bag.contains(TST_100.self))
    }

    // MARK: - After single add

    @Test("isEmpty is false after adding one value")
    func isEmptyFalseAfterAdd() {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 100))
        #expect(!bag.isEmpty)
    }

    @Test("currencyCodes contains added currency")
    func currencyCodesContainsAdded() {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 100))
        #expect(bag.currencyCodes == [TST_100.code])
    }

    @Test("contains returns true for added currency")
    func containsTrueAfterAdd() {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 100))
        #expect(bag.contains(TST_100.self))
    }

    @Test("contains returns false for different currency after add")
    func containsFalseForOtherCurrency() {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 100))
        #expect(!bag.contains(TST_1.self))
    }

    @Test("balance(of:) returns correct value after single add")
    func amountCorrectAfterSingleAdd() throws {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        let amount = try #require(bag.balance(of: TST_100.self))
        #expect(amount == Money<TST_100>(minorUnits: 500))
    }

    @Test("balance(of:) returns nil for absent currency after add")
    func amountNilForAbsentAfterAdd() {
        let bag = MoneyBag().adding(Money<TST_100>(minorUnits: 500))
        #expect(bag.balance(of: TST_1.self) == nil)
    }

    // MARK: - Multi-currency

    @Test("currencyCodes contains all added currencies")
    func currencyCodesMultiCurrency() {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 100))
            .adding(Money<TST_1>(minorUnits: 200))
        #expect(bag.currencyCodes == [TST_100.code, TST_1.code])
    }

    @Test("balances is sorted by currencyCode")
    func breakdownSorted() {
        // Adding TST_1 first, then TST_100 — breakdown must sort by code regardless
        // "TST_1" < "TST_100" lexicographically
        let bag = MoneyBag()
            .adding(Money<TST_1>(minorUnits: 200))
            .adding(Money<TST_100>(minorUnits: 100))
        let codes = bag.balances.map { String($0.currencyCode) }
        #expect(codes == ["TST_1", "TST_100"])
    }

    @Test("balances contains correct minorUnits for each currency")
    func breakdownMinorUnits() throws {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 999))
        let tst1Entry = try #require(bag.balances.first { $0.currencyCode == TST_1.code })
        let tst100Entry = try #require(bag.balances.first { $0.currencyCode == TST_100.code })
        #expect(tst1Entry.minorUnits == 999)
        #expect(tst100Entry.minorUnits == 500)
    }

    // MARK: - balances(where:)

    @Test("balances(where:) filters positive balances")
    func balancesWherePositive() {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: -100))
        let positive = bag.balances(where: { $0.minorUnits > 0 })
        #expect(positive.count == 1)
        #expect(positive.first?.currencyCode == TST_100.code)
    }

    @Test("balances(where:) filters by currency code")
    func balancesWhereCurrencyCode() {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 200))
        let filtered = bag.balances(where: { $0.currencyCode == TST_1.code })
        #expect(filtered.count == 1)
        #expect(filtered.first?.minorUnits == 200)
    }

    @Test("balances(where:) returns empty when no matches")
    func balancesWhereNoMatches() {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
        let filtered = bag.balances(where: { $0.minorUnits > 1000 })
        #expect(filtered.isEmpty)
    }

    @Test("balances(where:) with all-matching predicate equals balances")
    func balancesWhereAllMatch() {
        let bag = MoneyBag()
            .adding(Money<TST_100>(minorUnits: 500))
            .adding(Money<TST_1>(minorUnits: 200))
        let all = bag.balances(where: { _ in true })
        #expect(all == bag.balances)
    }
}
