import Foundation
import Testing
import SwiftMoney

@Suite("MoneyBag – Formatting")
struct MoneyBag_FormatStyleTests {

    // MARK: - Empty bag

    @Test("formatted() on an empty bag returns an empty string")
    func emptyBagFormatsAsEmpty() {
        #expect(MoneyBag().formatted() == "")
    }

    @Test("description on an empty bag returns an empty string")
    func emptyBagDescriptionIsEmpty() {
        #expect(MoneyBag().description == "")
    }

    // MARK: - Single-currency bag

    @Test("formatted() on a single-currency bag is non-empty")
    func singleCurrencyFormatsNonEmpty() {
        let bag = MoneyBag().adding(Money<GBP>(minorUnits: 150))
        #expect(!bag.formatted().isEmpty)
    }

    @Test("formatted() on a single-currency bag matches its AnyMoney formatted() output")
    func singleCurrencyMatchesAnyMoneyFormatted() {
        let money = Money<GBP>(minorUnits: 150)
        let bag = MoneyBag().adding(money)
        #expect(bag.formatted() == money.erased.formatted())
    }

    @Test("formatted() on a single-currency EUR bag matches its AnyMoney formatted() output")
    func singleCurrencyEURMatchesAnyMoney() {
        let money = Money<EUR>(minorUnits: 1050)
        let bag = MoneyBag().adding(money)
        #expect(bag.formatted() == money.erased.formatted())
    }

    // MARK: - Multi-currency bag

    @Test("formatted() on a two-currency bag is non-empty")
    func twoCurrencyFormatsNonEmpty() {
        let bag = MoneyBag()
            .adding(Money<GBP>(minorUnits: 500))
            .adding(Money<EUR>(minorUnits: 1000))
        #expect(!bag.formatted().isEmpty)
    }

    @Test("formatted() on a two-currency bag contains both formatted entries")
    func twoCurrencyContainsBothEntries() {
        let gbp = Money<GBP>(minorUnits: 500).erased.formatted()
        let eur = Money<EUR>(minorUnits: 1000).erased.formatted()
        let bag = MoneyBag()
            .adding(Money<GBP>(minorUnits: 500))
            .adding(Money<EUR>(minorUnits: 1000))
        let result = bag.formatted()
        #expect(result.contains(gbp))
        #expect(result.contains(eur))
    }

    @Test("formatted() entries appear in currency-code sort order")
    func formattedEntriesAreSorted() {
        // EUR < GBP lexicographically, so EUR entry should come first
        let eurFormatted = Money<EUR>(minorUnits: 1000).erased.formatted()
        let gbpFormatted = Money<GBP>(minorUnits: 500).erased.formatted()
        // Add GBP first to verify sorting is not insertion-order
        let bag = MoneyBag()
            .adding(Money<GBP>(minorUnits: 500))
            .adding(Money<EUR>(minorUnits: 1000))
        let result = bag.formatted()
        let eurRange = try! #require(result.range(of: eurFormatted))
        let gbpRange = try! #require(result.range(of: gbpFormatted))
        #expect(eurRange.lowerBound < gbpRange.lowerBound)
    }

    @Test("formatted() entries are joined by ', '")
    func formattedJoinedByCommaSpace() {
        let eurFormatted = Money<EUR>(minorUnits: 1000).erased.formatted()
        let gbpFormatted = Money<GBP>(minorUnits: 500).erased.formatted()
        let bag = MoneyBag()
            .adding(Money<GBP>(minorUnits: 500))
            .adding(Money<EUR>(minorUnits: 1000))
        // EUR < GBP, so separator falls between them
        #expect(bag.formatted() == "\(eurFormatted), \(gbpFormatted)")
    }

    // MARK: - CustomStringConvertible

    @Test("description equals formatted() for empty bag")
    func descriptionEqualsFormattedEmpty() {
        let bag = MoneyBag()
        #expect(bag.description == bag.formatted())
    }

    @Test("description equals formatted() for single-currency bag")
    func descriptionEqualsFormattedSingle() {
        let bag = MoneyBag().adding(Money<GBP>(minorUnits: 500))
        #expect(bag.description == bag.formatted())
    }

    @Test("description equals formatted() for multi-currency bag")
    func descriptionEqualsFormattedMulti() {
        let bag = MoneyBag()
            .adding(Money<GBP>(minorUnits: 500))
            .adding(Money<EUR>(minorUnits: 1000))
        #expect(bag.description == bag.formatted())
    }

    // MARK: - Negative entries

    @Test("formatted() handles a negative entry without crashing")
    func negativeEntryFormatsNonEmpty() {
        let bag = MoneyBag().subtracting(Money<GBP>(minorUnits: 200))
        #expect(!bag.formatted().isEmpty)
    }

    @Test("formatted() on a negative-entry bag matches its AnyMoney formatted() output")
    func negativeEntryMatchesAnyMoney() {
        let money = Money<GBP>(minorUnits: 200)
        let bag = MoneyBag().subtracting(money)
        let negated = (-money).erased.formatted()
        #expect(bag.formatted() == negated)
        
        
        let x = 3.formatted(.currency(code: "GBP"))
    }
}
