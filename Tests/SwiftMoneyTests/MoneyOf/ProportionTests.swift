import SwiftMoney
import Testing

@Suite("Proportion Tests")
struct ProportionTests {

    // MARK: - A currency fixed at compile time

    @Test("A part of a whole is the fraction between them")
    func partOfWhole() throws {
        let part = GBP(minorUnits: 20_00)
        let whole = GBP(minorUnits: 100_00)

        #expect(part.proportion(of: whole) == "1/5")
    }

    @Test("The whole is all of itself")
    func wholeOfItself() {
        let whole = GBP(minorUnits: 4_99)

        #expect(whole.proportion(of: whole) == "1/1")
    }

    @Test("Nothing is none of something")
    func zeroOfSomething() {
        #expect(GBP.zero.proportion(of: GBP(minorUnits: 100_00)) == "0/1")
    }

    @Test("Nothing has no parts, so a proportion of zero is nil")
    func somethingOfZero() {
        #expect(GBP(minorUnits: 100_00).proportion(of: .zero) == nil)
        #expect(GBP.zero.proportion(of: .zero) == nil)
    }

    @Test("A part larger than the whole is more than one")
    func partLargerThanWhole() {
        let part = GBP(minorUnits: 250_00)
        let whole = GBP(minorUnits: 100_00)

        #expect(part.proportion(of: whole) == "5/2")
    }

    // The result is a `Ratio`, which reduces, so this is really checking that nothing upstream
    // depends on the unreduced form.
    @Test("The proportion is in lowest terms")
    func lowestTerms() {
        let part = GBP(minorUnits: 22)
        let whole = GBP(minorUnits: 200)

        #expect(part.proportion(of: whole) == "11/100")
    }

    @Test("A negative part gives a negative proportion")
    func negativePart() {
        let part = GBP(minorUnits: -20_00)
        let whole = GBP(minorUnits: 100_00)

        #expect(part.proportion(of: whole) == "-1/5")
    }

    @Test("A negative whole gives a negative proportion")
    func negativeWhole() {
        let part = GBP(minorUnits: 20_00)
        let whole = GBP(minorUnits: -100_00)

        #expect(part.proportion(of: whole) == "-1/5")
    }

    @Test("Two negatives give a positive proportion")
    func bothNegative() {
        let part = GBP(minorUnits: -20_00)
        let whole = GBP(minorUnits: -100_00)

        #expect(part.proportion(of: whole) == "1/5")
    }

    // MARK: - The extremes

    @Test("The largest and smallest amounts are each all of themselves")
    func extremesOfThemselves() {
        #expect(GBP.max.proportion(of: .max) == "1/1")
        #expect(GBP.min.proportion(of: .min) == "1/1")
    }

    // The smallest amount has no positive counterpart, so this proportion is one greater than the
    // largest numerator. It reports rather than traps, since neither amount is itself invalid.
    @Test("A proportion too large to represent is nil")
    func unrepresentableProportion() {
        #expect(GBP.min.proportion(of: GBP(minorUnits: -1)) == nil)
    }

    // Halving brings the same pair back into range, which is only true if the fraction is reduced
    // before it is checked.
    @Test("A proportion is reduced before it is judged unrepresentable")
    func reducedBeforeJudged() {
        #expect(GBP.min.proportion(of: GBP(minorUnits: -2)) != nil)
    }

    // MARK: - A currency only known at runtime

    @Test("A part of a whole in the same currency is the fraction between them")
    func runtimePartOfWhole() throws {
        let part = Money(minorUnits: 20_00, currency: .eur)
        let whole = Money(minorUnits: 100_00, currency: .eur)

        #expect(try part.proportion(of: whole) == "1/5")
    }

    @Test("A proportion across two currencies throws, naming both")
    func runtimeCurrencyMismatch() {
        let part = Money(minorUnits: 20_00, currency: .gbp)
        let whole = Money(minorUnits: 100_00, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try part.proportion(of: whole)
        }
    }

    @Test("A runtime proportion of zero is nil")
    func runtimeProportionOfZero() throws {
        let part = Money(minorUnits: 100_00, currency: .gbp)
        let whole = Money(minorUnits: 0, currency: .gbp)

        #expect(try part.proportion(of: whole) == nil)
    }
}
