import SwiftMoneyCore
import Testing

private typealias Credits = MoneyOf<Millicredits>
private typealias TypedStepsError = MoneyStepsParsingError<Currencies.GBP>
private typealias RuntimeStepsError = MoneyStepsParsingError<AnyCurrency>

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

private func yen(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .jpy)
}

@Suite("MoneyOf.Steps from untrusted bounds and step")
struct StepsParsingTests {

    @Test("Named bounds of 0 and 250 by −100 start on the upper one, typed and runtime")
    func namedBoundsCountDown() throws {
        let typed = try JPY.Steps(checkedBounds: (lower: JPY(minorUnits: 0), upper: JPY(minorUnits: 250)), by: JPY(minorUnits: -100))
        let runtime = try Money.Steps(checkedBounds: (lower: yen(0), upper: yen(250)), by: yen(-100))

        #expect(typed.map(\.minorUnits) == [250, 150, 50, 0])
        #expect(Array(runtime).map(\.minorUnits) == [250, 150, 50, 0])
    }

    @Test("Named bounds of 250 and 0 throw invertedBounds, typed and runtime")
    func namedBoundsInverted() {
        let typedInverted = MoneyStepsParsingError<Currencies.JPY>.invertedBounds(
            lowerBound: JPY(minorUnits: 250),
            upperBound: JPY(minorUnits: 0)
        )

        #expect(throws: typedInverted) {
            try JPY.Steps(checkedBounds: (lower: JPY(minorUnits: 250), upper: JPY(minorUnits: 0)), by: JPY(minorUnits: 100))
        }
        #expect(throws: RuntimeStepsError.invertedBounds(lowerBound: yen(250), upperBound: yen(0))) {
            try Money.Steps(checkedBounds: (lower: yen(250), upper: yen(0)), by: yen(100))
        }
    }

    @Test("Bounds and a raw step from a server build the steps a range and a stride would")
    func typedEqualsRangeSteps() throws {
        let parsed = try GBP.Steps(checkedBounds: (lower: GBP(minorUnits: 10_00), upper: GBP(minorUnits: 250_00)), by: GBP(minorUnits: 100_00))
        let stepped = try (GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)).steps(by: .majorUnits(100))

        #expect(parsed == stepped)
        #expect(parsed.map(\.minorUnits) == [10_00, 110_00, 210_00, 250_00])
    }

    @Test("A custom currency parses the same way")
    func customCurrencyParses() throws {
        let credits = try Credits.Steps(checkedBounds: (lower: Credits(minorUnits: 0), upper: Credits(minorUnits: 2_500)), by: Credits(minorUnits: 1_000))

        #expect(credits.map(\.minorUnits) == [0, 1_000, 2_000, 2_500])
    }

    @Test("Typed inverted bounds throw invertedBounds with both bounds")
    func typedInverted() {
        let inverted = TypedStepsError.invertedBounds(lowerBound: GBP(minorUnits: 250_00), upperBound: GBP(minorUnits: 10_00))

        #expect(throws: inverted) {
            try GBP.Steps(checkedBounds: (lower: GBP(minorUnits: 250_00), upper: GBP(minorUnits: 10_00)), by: GBP(minorUnits: 1_00))
        }
    }

    @Test("A typed zero step throws zeroStride; one too fine to count throws tooManySteps")
    func typedZeroAndTooMany() {
        #expect(throws: TypedStepsError.zeroStride) {
            try GBP.Steps(checkedBounds: (lower: .zero, upper: GBP(minorUnits: 1_00)), by: .zero)
        }
        #expect(throws: TypedStepsError.tooManySteps) {
            try GBP.Steps(checkedBounds: (lower: .min, upper: .max), by: GBP(minorUnits: 1))
        }
    }

    @Test("Typed parsing throws only MoneyStepsParsingError, so a switch needs no mismatch branch")
    func typedThrowsExactly() {
        do throws(TypedStepsError) {
            _ = try GBP.Steps(checkedBounds: (lower: .min, upper: .max), by: GBP(minorUnits: -1))
            Issue.record("Expected too many steps to throw")
        } catch {
            switch error {
            case .invertedBounds, .zeroStride:
                Issue.record("Expected too many steps, not \(error)")
            case .tooManySteps:
                break
            }
        }
    }

    @Test("Inverted bounds are reported before a zero step")
    func typedOrder() {
        #expect(throws: TypedStepsError.invertedBounds(lowerBound: GBP(minorUnits: 2), upperBound: GBP(minorUnits: 1))) {
            try GBP.Steps(checkedBounds: (lower: GBP(minorUnits: 2), upper: GBP(minorUnits: 1)), by: .zero)
        }
    }

    @Test("Runtime bounds and step in one currency build the steps a range and a stride would")
    func runtimeEqualsRangeSteps() throws {
        let parsed = try Money.Steps(checkedBounds: (lower: pounds(10_00), upper: pounds(250_00)), by: pounds(-100_00))
        let stepped = try (pounds(10_00)...pounds(250_00)).steps(by: #require(.majorUnits(-100, of: .gbp)))
        let typed = try GBP.Steps(
            checkedBounds: (lower: GBP(minorUnits: 10_00), upper: GBP(minorUnits: 250_00)),
            by: GBP(minorUnits: -100_00)
        )

        #expect(parsed == stepped)
        #expect(parsed == Money.Steps(typed))
    }

    @Test("An upper bound, or else a step, in another currency throws a mismatch with its currency")
    func runtimeMismatch() {
        let euros = Money(minorUnits: 100, currency: .eur)

        #expect(throws: RuntimeStepsError.currencyMismatch(.jpy)) {
            try Money.Steps(checkedBounds: (lower: pounds(0), upper: yen(100)), by: pounds(1_00))
        }
        #expect(throws: RuntimeStepsError.currencyMismatch(.jpy)) {
            try Money.Steps(checkedBounds: (lower: pounds(0), upper: pounds(5_00)), by: yen(100))
        }
        #expect(throws: RuntimeStepsError.currencyMismatch(.eur)) {
            try Money.Steps(checkedBounds: (lower: pounds(5_00), upper: euros), by: yen(100))
        }
    }

    @Test("A mismatched step is reported before inverted bounds; inverted before a zero step")
    func runtimeOrder() {
        #expect(throws: RuntimeStepsError.currencyMismatch(.jpy)) {
            try Money.Steps(checkedBounds: (lower: pounds(5_00), upper: pounds(0)), by: yen(0))
        }
        #expect(throws: RuntimeStepsError.invertedBounds(lowerBound: pounds(5_00), upperBound: pounds(0))) {
            try Money.Steps(checkedBounds: (lower: pounds(5_00), upper: pounds(0)), by: pounds(0))
        }
    }

    @Test("A runtime zero step or one too fine to count throws the case naming it")
    func runtimeZeroAndTooMany() {
        let lowest = Money(minorUnits: Int64.min, currency: .gbp)
        let highest = Money(minorUnits: Int64.max, currency: .gbp)

        #expect(throws: RuntimeStepsError.zeroStride) {
            try Money.Steps(checkedBounds: (lower: pounds(0), upper: pounds(1_00)), by: pounds(0))
        }
        #expect(throws: RuntimeStepsError.tooManySteps) {
            try Money.Steps(checkedBounds: (lower: lowest, upper: highest), by: pounds(1))
        }
    }

    @Test("A custom currency at another scale is a mismatch")
    func runtimeScaleMismatch() {
        let coarse = customCurrency(code: "MCR", unitScale: 1)
        let fine = Millicredits.currency

        #expect(throws: RuntimeStepsError.currencyMismatch(coarse)) {
            try Money.Steps(
                checkedBounds: (lower: Money(minorUnits: 0, currency: fine), upper: Money(minorUnits: 10, currency: coarse)),
                by: Money(minorUnits: 1, currency: fine)
            )
        }
    }
}
