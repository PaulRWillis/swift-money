import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

@Suite("min and max over runtime amounts")
struct MinMaxFunctionsTests {

    @Test("min and max of two amounts give the smaller and the larger, in either order")
    func twoAmounts() throws {
        #expect(try min(pounds(5_00), pounds(7_00)) == pounds(5_00))
        #expect(try min(pounds(7_00), pounds(5_00)) == pounds(5_00))
        #expect(try max(pounds(5_00), pounds(7_00)) == pounds(7_00))
        #expect(try max(pounds(7_00), pounds(5_00)) == pounds(7_00))
    }

    @Test("min and max order negative amounts below zero")
    func negatives() throws {
        #expect(try min(pounds(-3_00), pounds(0)) == pounds(-3_00))
        #expect(try max(pounds(-3_00), pounds(0)) == pounds(0))
        #expect(try min(pounds(-3_00), pounds(-1)) == pounds(-3_00))
        #expect(try max(pounds(-3_00), pounds(-1)) == pounds(-1))
    }

    @Test("min and max reach the smallest and largest amounts")
    func extremes() throws {
        #expect(try min(pounds(Int64.min), pounds(Int64.max)) == pounds(Int64.min))
        #expect(try min(pounds(Int64.max), pounds(Int64.min)) == pounds(Int64.min))
        #expect(try max(pounds(Int64.min), pounds(Int64.max)) == pounds(Int64.max))
        #expect(try max(pounds(Int64.max), pounds(Int64.min)) == pounds(Int64.max))
    }

    // Equal amounts are bit-identical, so which argument comes back cannot be observed.
    @Test("min and max of equal amounts give that amount")
    func equalAmounts() throws {
        #expect(try min(pounds(4_99), pounds(4_99)) == pounds(4_99))
        #expect(try max(pounds(4_99), pounds(4_99)) == pounds(4_99))
    }

    @Test("Amounts in different currencies throw a mismatch, the first argument's currency first")
    func mismatch() {
        let yen = Money(minorUnits: 500, currency: .jpy)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .jpy)) { try min(pounds(5_00), yen) }
        #expect(throws: MoneyError.currencyMismatch(lhs: .jpy, rhs: .gbp)) { try min(yen, pounds(5_00)) }
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .jpy)) { try max(pounds(5_00), yen) }
        #expect(throws: MoneyError.currencyMismatch(lhs: .jpy, rhs: .gbp)) { try max(yen, pounds(5_00)) }
    }

    @Test("The same code at another scale is another currency, so it throws a mismatch")
    func sameCodeOtherScale() {
        let wholeCredits = customCurrency(code: "KHO", unitScale: 1)
        let centiCredits = customCurrency(code: "KHO", unitScale: 100)
        let whole = Money(minorUnits: 1, currency: wholeCredits)
        let centi = Money(minorUnits: 1, currency: centiCredits)
        let mismatch = MoneyError.currencyMismatch(lhs: wholeCredits, rhs: centiCredits)

        #expect(throws: mismatch) { try min(whole, centi) }
        #expect(throws: mismatch) { try max(whole, centi) }
    }

    @Test("The error stays a MoneyError, with no cast")
    func typedError() {
        let euros = Money(minorUnits: 5_00, currency: .eur)

        do throws(MoneyError) {
            _ = try min(pounds(5_00), euros)
            Issue.record("min of pounds and euros returned")
        } catch {
            #expect(error == .currencyMismatch(lhs: .gbp, rhs: .eur))
        }

        do throws(MoneyError) {
            _ = try max(pounds(5_00), euros)
            Issue.record("max of pounds and euros returned")
        } catch {
            #expect(error == .currencyMismatch(lhs: .gbp, rhs: .eur))
        }
    }

    @Test("min and max of three or more amounts find the extreme wherever it is")
    func threeOrMore() throws {
        #expect(try min(pounds(1_00), pounds(5_00), pounds(3_00)) == pounds(1_00))
        #expect(try min(pounds(5_00), pounds(1_00), pounds(3_00)) == pounds(1_00))
        #expect(try min(pounds(5_00), pounds(3_00), pounds(1_00)) == pounds(1_00))
        #expect(try min(pounds(5_00), pounds(3_00), pounds(4_00), pounds(2_00), pounds(-1_00)) == pounds(-1_00))
        #expect(try max(pounds(9_00), pounds(5_00), pounds(3_00)) == pounds(9_00))
        #expect(try max(pounds(5_00), pounds(9_00), pounds(3_00)) == pounds(9_00))
        #expect(try max(pounds(5_00), pounds(3_00), pounds(9_00)) == pounds(9_00))
        #expect(try max(pounds(5_00), pounds(3_00), pounds(4_00), pounds(Int64.max), pounds(2_00)) == pounds(Int64.max))
    }

    @Test("A mismatch in the third amount or later names the first amount's currency and the first that differs")
    func threeOrMoreMismatch() {
        let euros = Money(minorUnits: 5_00, currency: .eur)
        let yen = Money(minorUnits: 500, currency: .jpy)
        let gbpThenEuro = MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)

        #expect(throws: gbpThenEuro) { try min(pounds(1_00), euros, yen) }
        #expect(throws: gbpThenEuro) { try max(pounds(1_00), euros, yen) }
        #expect(throws: gbpThenEuro) { try min(pounds(1_00), pounds(2_00), euros) }
        #expect(throws: gbpThenEuro) { try max(pounds(1_00), pounds(2_00), euros) }
        #expect(throws: gbpThenEuro) { try min(pounds(1_00), pounds(2_00), pounds(3_00), euros, yen) }
        #expect(throws: gbpThenEuro) { try max(pounds(1_00), pounds(2_00), pounds(3_00), euros, yen) }
    }

    @Test("A mismatch on an amount that isn't the extreme still throws")
    func threeOrMoreMismatchOffTheExtreme() {
        let largeEuros = Money(minorUnits: 900_00, currency: .eur)
        let smallEuros = Money(minorUnits: -900_00, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try min(pounds(1_00), pounds(2_00), pounds(3_00), largeEuros)
        }
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try max(pounds(1_00), pounds(2_00), pounds(3_00), smallEuros)
        }
    }

    @Test("min and max of numbers and typed amounts still need no try with SwiftMoneyCore imported")
    func standardLibraryUnaffected() {
        #expect(min(1, 2) == 1)
        #expect(max(1.5, 2) == 2)
        #expect(min(GBP(minorUnits: 5_00), GBP(minorUnits: 7_00)) == GBP(minorUnits: 5_00))
        #expect(max(GBP(minorUnits: 5_00), GBP(minorUnits: 7_00)) == GBP(minorUnits: 7_00))
        #expect(min(3, 1, 2) == 1)
        #expect(max(3, 1, 2) == 3)
    }
}
