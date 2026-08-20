import SwiftMoney
import Testing

@Suite("Total Tests")
struct TotalTests {

    // MARK: - MoneyOf

    @Test("Totalling typed amounts sums them")
    func totalOfTypedAmounts() {
        #expect([GBP(minorUnits: 1_00), GBP(minorUnits: 2_50), GBP(minorUnits: 0_49)].total() == GBP(minorUnits: 3_99))
    }

    // MoneyOf has a zero, so the total of nothing is zero rather than absent.
    @Test("Totalling no typed amounts is zero")
    func totalOfNoTypedAmounts() {
        #expect([GBP]().total() == GBP.zero)
    }

    @Test("Totalling a single typed amount is that amount")
    func totalOfOneTypedAmount() {
        #expect([GBP(minorUnits: 4_99)].total() == GBP(minorUnits: 4_99))
    }

    // MARK: - Money

    @Test("Totalling untyped amounts of one currency sums them")
    func totalOfUntypedAmounts() throws {
        let amounts = [
            Money(minorUnits: 1_00, currency: .gbp),
            Money(minorUnits: 2_50, currency: .gbp),
            Money(minorUnits: 0_49, currency: .gbp),
        ]

        #expect(try amounts.total() == Money(minorUnits: 3_99, currency: .gbp))
    }

    // Money has no zero — one cannot exist without a currency — so an empty sequence has no total.
    @Test("Totalling no untyped amounts is nil")
    func totalOfNoUntypedAmounts() throws {
        #expect(try [Money]().total() == nil)
    }

    @Test("Totalling a single untyped amount is that amount")
    func totalOfOneUntypedAmount() throws {
        #expect(try [Money(minorUnits: 4_99, currency: .gbp)].total() == Money(minorUnits: 4_99, currency: .gbp))
    }

    @Test("Totalling mixed currencies throws, naming both")
    func totalOfMixedCurrencies() {
        let amounts = [
            Money(minorUnits: 1_00, currency: .gbp),
            Money(minorUnits: 2_50, currency: .eur),
        ]

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try amounts.total()
        }
    }

    @Test("Totalling traps on overflow")
    func totalTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            let amounts = [
                Money(minorUnits: Int64.max, currency: .gbp),
                Money(minorUnits: 1, currency: .gbp),
            ]

            blackHole(try amounts.total())
        }
    }

    @Test("Totalling traps on underflow")
    func totalTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            let amounts = [
                Money(minorUnits: Int64.min, currency: .gbp),
                Money(minorUnits: -1, currency: .gbp),
            ]

            blackHole(try amounts.total())
        }
    }

    // MARK: - Unrounded

    // Three thirds of a penny total a penny. Settling each one first would total nothing.
    @Test("Totalling unrounded typed amounts stays exact")
    func totalOfUnroundedTypedAmounts() {
        let third = GBP(minorUnits: 1).unrounded * Ratio(1, 3)

        #expect([third, third, third].total().rounded(.towardZero) == GBP(minorUnits: 1))
    }

    @Test("Totalling no unrounded typed amounts is zero")
    func totalOfNoUnroundedTypedAmounts() {
        #expect([GBP.Unrounded]().total() == GBP.Unrounded.zero)
    }

    @Test("Totalling unrounded untyped amounts stays exact")
    func totalOfUnroundedUntypedAmounts() throws {
        let third = Money(minorUnits: 1, currency: .eur).unrounded * Ratio(1, 3)

        let summed = try [third, third, third].total()
        let total = try #require(summed)

        #expect(total.rounded(.towardZero) == Money(minorUnits: 1, currency: .eur))
    }

    @Test("Totalling no unrounded untyped amounts is nil")
    func totalOfNoUnroundedUntypedAmounts() throws {
        #expect(try [Money.Unrounded]().total() == nil)
    }

    @Test("Totalling unrounded amounts of mixed currencies throws, naming both")
    func totalOfUnroundedMixedCurrencies() {
        let amounts = [
            Money(minorUnits: 1_00, currency: .gbp).unrounded,
            Money(minorUnits: 2_50, currency: .eur).unrounded,
        ]

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try amounts.total()
        }
    }

    // MARK: - Any Sequence

    @Test("Totalling works on any sequence, not only arrays")
    func totalOfAnySequence() throws {
        let typed = [1, 2, 3].lazy.map { GBP(minorUnits: $0) }
        #expect(typed.total() == GBP(minorUnits: 6)) // 1 + 2 + 3

        let untyped = [1, 2, 3].lazy.map { Money(minorUnits: $0, currency: .gbp) }
        #expect(try untyped.total() == Money(minorUnits: 6, currency: .gbp))
    }
}
