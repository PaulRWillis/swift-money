import SwiftMoney
import Testing

@Suite("Proportion Tests")
struct ProportionTests {

    @Test("A part of a whole is the fraction between them")
    func partOfWhole() {
        let part = GBP(minorUnits: 20_00)
        let whole = GBP(minorUnits: 100_00)

        #expect(part.proportion(of: whole) == Rate.percent(20))
    }

    @Test("The whole is all of itself")
    func wholeOfItself() {
        let whole = GBP(minorUnits: 4_99)

        #expect(whole.proportion(of: whole) == "1")
    }

    @Test("Nothing is none of something")
    func zeroOfSomething() {
        #expect(GBP.zero.proportion(of: GBP(minorUnits: 100_00)) == "0")
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

        #expect(part.proportion(of: whole) == "2.5")
    }

    @Test("A part smaller than the whole is a decimal fraction")
    func smallPart() {
        let part = GBP(minorUnits: 22)
        let whole = GBP(minorUnits: 200)

        #expect(part.proportion(of: whole) == "0.11")
    }

    @Test("A negative part gives a negative proportion")
    func negativePart() {
        let part = GBP(minorUnits: -20_00)
        let whole = GBP(minorUnits: 100_00)

        #expect(part.proportion(of: whole) == Rate.percent(-20))
    }

    @Test("A negative whole gives a negative proportion")
    func negativeWhole() {
        let part = GBP(minorUnits: 20_00)
        let whole = GBP(minorUnits: -100_00)

        #expect(part.proportion(of: whole) == Rate.percent(-20))
    }

    @Test("Two negatives give a positive proportion")
    func bothNegative() {
        let part = GBP(minorUnits: -20_00)
        let whole = GBP(minorUnits: -100_00)

        #expect(part.proportion(of: whole) == Rate.percent(20))
    }

    @Test("The largest and smallest amounts are each all of themselves")
    func extremesOfThemselves() {
        #expect(GBP.max.proportion(of: .max) == "1")
        #expect(GBP.min.proportion(of: .min) == "1")
    }

    // proportion is the inverse of scaling: measuring a part against a whole, then scaling the whole by
    // that fraction, returns the part — within one minor unit, since the fraction is a decimal rounded
    // once on the way back.
    @Test("Proportion inverts scaling", arguments: [
        (GBP(minorUnits: 20_00), GBP(minorUnits: 100_00)),
        (GBP(minorUnits: 33), GBP(minorUnits: 100)),        // 0.33 exactly
        (GBP(minorUnits: 7), GBP(minorUnits: 3)),           // 2.333..., a non-terminating fraction
        (GBP(minorUnits: -250), GBP(minorUnits: 1_000)),
    ])
    func proportionInvertsScaling(_ pair: (part: GBP, whole: GBP)) throws {
        let fraction = try #require(pair.part.proportion(of: pair.whole))

        #expect(pair.whole.applying(fraction).rounded(.toNearestOrEven) == pair.part)
    }

    @Test("A part of a whole in the same currency is the fraction between them")
    func runtimePartOfWhole() throws {
        let part = Money(minorUnits: 20_00, currency: .eur)
        let whole = Money(minorUnits: 100_00, currency: .eur)

        #expect(try part.proportion(of: whole) == Rate.percent(20))
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
