import SwiftMoney
import Testing

@Suite("Total Tests")
struct TotalTests {

    // MARK: - MoneyOf

    @Test("Totalling typed amounts sums them")
    func totalOfTypedAmounts() {
        #expect([GBP(1_00), GBP(2_50), GBP(0_49)].total() == GBP(3_99))
    }

    // MoneyOf has a zero, so the total of nothing is zero rather than absent.
    @Test("Totalling no typed amounts is zero")
    func totalOfNoTypedAmounts() {
        #expect([GBP]().total() == GBP.zero)
    }

    @Test("Totalling a single typed amount is that amount")
    func totalOfOneTypedAmount() {
        #expect([GBP(4_99)].total() == GBP(4_99))
    }

    // MARK: - Money

    @Test("Totalling untyped amounts of one currency sums them")
    func totalOfUntypedAmounts() throws {
        let amounts = [
            Money(1_00, currency: .gbp),
            Money(2_50, currency: .gbp),
            Money(0_49, currency: .gbp),
        ]

        #expect(try amounts.total() == Money(3_99, currency: .gbp))
    }

    // Money has no zero — one cannot exist without a currency — so an empty sequence has no total.
    @Test("Totalling no untyped amounts is nil")
    func totalOfNoUntypedAmounts() throws {
        #expect(try [Money]().total() == nil)
    }

    @Test("Totalling a single untyped amount is that amount")
    func totalOfOneUntypedAmount() throws {
        #expect(try [Money(4_99, currency: .gbp)].total() == Money(4_99, currency: .gbp))
    }

    @Test("Totalling mixed currencies throws, naming both")
    func totalOfMixedCurrencies() {
        let amounts = [
            Money(1_00, currency: .gbp),
            Money(2_50, currency: .eur),
        ]

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try amounts.total()
        }
    }

    @Test("Totalling propagates overflow")
    func totalPropagatesOverflow() {
        let amounts = [
            Money(Int64.max, currency: .gbp),
            Money(1, currency: .gbp),
        ]

        #expect(throws: MoneyError.overflow) {
            try amounts.total()
        }
    }

    // MARK: - Unrounded

    // Three thirds of a penny total a penny. Settling each one first would total nothing.
    @Test("Totalling unrounded typed amounts stays exact")
    func totalOfUnroundedTypedAmounts() {
        let third = GBP(1).unrounded * Ratio(1, 3)

        #expect([third, third, third].total().rounded(.towardZero) == GBP(1))
    }

    @Test("Totalling no unrounded typed amounts is zero")
    func totalOfNoUnroundedTypedAmounts() {
        #expect([GBP.Unrounded]().total() == GBP.Unrounded.zero)
    }

    @Test("Totalling unrounded untyped amounts stays exact")
    func totalOfUnroundedUntypedAmounts() throws {
        let third = try Money(1, currency: .eur).unrounded * Ratio(1, 3)

        let summed = try [third, third, third].total()
        let total = try #require(summed)

        #expect(total.rounded(.towardZero) == Money(1, currency: .eur))
    }

    @Test("Totalling no unrounded untyped amounts is nil")
    func totalOfNoUnroundedUntypedAmounts() throws {
        #expect(try [Money.Unrounded]().total() == nil)
    }

    @Test("Totalling unrounded amounts of mixed currencies throws, naming both")
    func totalOfUnroundedMixedCurrencies() {
        let amounts = [
            Money(1_00, currency: .gbp).unrounded,
            Money(2_50, currency: .eur).unrounded,
        ]

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try amounts.total()
        }
    }

    // MARK: - Any Sequence

    @Test("Totalling works on any sequence, not only arrays")
    func totalOfAnySequence() throws {
        let typed = stride(from: GBP(1), to: GBP(4), by: 1)
        #expect(typed.total() == GBP(6)) // 1 + 2 + 3

        let untyped = [1, 2, 3].lazy.map { Money($0, currency: .gbp) }
        #expect(try untyped.total() == Money(6, currency: .gbp))
    }
}
