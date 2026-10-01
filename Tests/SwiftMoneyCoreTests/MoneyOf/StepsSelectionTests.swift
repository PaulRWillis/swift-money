import SwiftMoneyCore
import Testing

private typealias Credits = MoneyOf<Millicredits>

private func pounds(_ minorUnits: Int64) -> GBP {
    GBP(minorUnits: minorUnits)
}

// £10, £110, £210 and £250.
private func tenToTwoFifty() throws -> GBP.Steps {
    try (pounds(10_00) ... pounds(250_00)).steps(by: .majorUnits(100))
}

private let everyRule: [RoundingRule] = [
    .down, .up, .towardZero, .awayFromZero, .toNearestOrEven, .toNearestOrAwayFromZero,
]

@Suite("MoneyOf.Steps.Selection")
struct StepsSelectionTests {

    @Test("A selection rounds its amount onto a step, by the nearest step unless told otherwise")
    func roundsOntoAStep() throws {
        let steps = try tenToTwoFifty()

        #expect(GBP.Steps.Selection(approximating: pounds(123_45), in: steps).amount == pounds(110_00))
        #expect(GBP.Steps.Selection(approximating: pounds(160_00), in: steps).index == 2)
        #expect(GBP.Steps.Selection(approximating: pounds(123_45), in: steps, rounding: .up).amount == pounds(210_00))
        #expect(GBP.Steps.Selection(approximating: pounds(999_00), in: steps, rounding: .down).amount == pounds(250_00))
    }

    @Test("Every rule picks the step index(approximating:rounding:) finds", arguments: everyRule)
    func matchesIndexForAmount(_ rule: RoundingRule) throws {
        let steps = try tenToTwoFifty()
        let saved = pounds(123_45)
        let selection = GBP.Steps.Selection(approximating: saved, in: steps, rounding: rule)

        #expect(selection.index == steps.index(approximating: saved, rounding: rule))
        #expect(selection.amount == steps[selection.index])
        #expect(selection.steps == steps)
    }

    @Test("An amount on a step, such as the upper bound, is kept under every rule", arguments: everyRule)
    func onAStepIsKept(_ rule: RoundingRule) throws {
        let steps = try tenToTwoFifty()

        #expect(GBP.Steps.Selection(approximating: pounds(250_00), in: steps, rounding: rule).amount == pounds(250_00))
        #expect(GBP.Steps.Selection(approximating: pounds(110_00), in: steps, rounding: rule).amount == pounds(110_00))
    }

    @Test("Selecting a position in the steps moves there; any other position is nil")
    func selectingAnIndex() throws {
        let steps = try tenToTwoFifty()
        let selection = GBP.Steps.Selection(approximating: pounds(10_00), in: steps)

        #expect(selection.selecting(3)?.amount == pounds(250_00))
        #expect(selection.selecting(0)?.amount == pounds(10_00))
        #expect(selection.selecting(steps.index(after: steps.startIndex))?.amount == pounds(110_00))
        #expect(selection.selecting(steps.endIndex) == nil)
        #expect(selection.selecting(4) == nil)
        #expect(selection.selecting(steps.index(before: steps.startIndex)) == nil)
    }

    @Test("Selecting an amount rounds it onto the same steps")
    func selectingAnAmount() throws {
        let selection = GBP.Steps.Selection(approximating: pounds(10_00), in: try tenToTwoFifty())

        #expect(selection.selecting(approximating: pounds(200_00)).amount == pounds(210_00))
        #expect(selection.selecting(approximating: pounds(200_00), rounding: .down).amount == pounds(110_00))
        #expect(selection.selecting(approximating: pounds(200_00)).steps == selection.steps)
    }

    @Test("Across zero, toward and away from zero select by size, typed and runtime")
    func acrossZeroBySize() throws {
        let steps = try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(20))
        let straddling = try (pounds(-7_00) ... pounds(17_00)).steps(by: .majorUnits(12))
        let selection = GBP.Steps.Selection(approximating: pounds(3_00), in: steps, rounding: .towardZero)
        let runtime = try Money.Steps.Selection(approximating: Money(pounds(3_00)), in: Money.Steps(straddling), rounding: .towardZero)

        #expect(selection.amount == pounds(10_00))
        #expect(selection.selecting(approximating: pounds(-3_00), rounding: .awayFromZero).amount == pounds(-10_00))
        #expect(runtime.amount == Money(pounds(5_00)))
        #expect(try runtime.selecting(approximating: Money(pounds(3_00)), rounding: .awayFromZero).amount == Money(pounds(-7_00)))
    }

    @Test("Yen and a custom currency select in their own units")
    func yenAndCustomCurrency() throws {
        let yen = try (JPY(minorUnits: 0) ... JPY(minorUnits: 1_000)).steps(by: .majorUnits(300))
        let credits = try (Credits.zero ... Credits(minorUnits: 5_000)).steps(by: .majorUnits(2))

        #expect(JPY.Steps.Selection(approximating: JPY(minorUnits: 950), in: yen).amount == JPY(minorUnits: 1_000))
        #expect(Credits.Steps.Selection(approximating: Credits(minorUnits: 3_999), in: credits, rounding: .down).index == 1)
    }

    @Test("Equal selections hash equally; the same position in other steps is a different selection")
    func equalityAndHash() throws {
        let steps = try tenToTwoFifty()
        let other = try (pounds(10_00) ... pounds(250_00)).steps(by: .majorUnits(50))
        let first = GBP.Steps.Selection(approximating: pounds(110_00), in: steps)
        let again = GBP.Steps.Selection(approximating: pounds(120_00), in: steps)

        #expect(first == again)
        #expect(first.hashValue == again.hashValue)
        #expect(first != GBP.Steps.Selection(approximating: pounds(210_00), in: steps))
        #expect(first != GBP.Steps.Selection(approximating: pounds(60_00), in: other))
        #expect(first.index == GBP.Steps.Selection(approximating: pounds(60_00), in: other).index)
    }

    @Test("A runtime selection rounds as a typed one does and selects the same way")
    func runtimeMatchesTyped() throws {
        let typed = GBP.Steps.Selection(approximating: pounds(123_45), in: try tenToTwoFifty(), rounding: .up)
        let runtime = try Money.Steps.Selection(approximating: Money(pounds(123_45)), in: Money.Steps(typed.steps), rounding: .up)

        #expect(runtime.amount == Money(typed.amount))
        #expect(runtime == Money.Steps.Selection(typed))
        #expect(try runtime.selecting(approximating: Money(pounds(200_00))).amount == Money(pounds(210_00)))
        #expect(try runtime.selecting(approximating: Money(pounds(200_00)), rounding: .down).amount == Money(pounds(110_00)))
        #expect(runtime.selecting(0)?.amount == Money(pounds(10_00)))
        #expect(runtime.selecting(runtime.steps.endIndex) == nil)
    }

    @Test("A runtime amount in another currency throws a mismatch, the steps' currency first")
    func runtimeMismatch() throws {
        let steps = Money.Steps(try tenToTwoFifty())
        let euros = Money(minorUnits: 60_00, currency: .eur)
        let selection = try Money.Steps.Selection(approximating: Money(pounds(60_00)), in: steps)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try Money.Steps.Selection(approximating: euros, in: steps)
        }
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try selection.selecting(approximating: euros, rounding: .down)
        }
    }

    @Test("Typed selections become runtime ones and back; another currency or scale throws")
    func conversions() throws {
        let credits = try (Credits.zero ... Credits(minorUnits: 5_000)).steps(by: .majorUnits(2))
        let typed = Credits.Steps.Selection(approximating: Credits(minorUnits: 3_000), in: credits)
        let runtime = Money.Steps.Selection(typed)
        let yen = Money.Steps.Selection(JPY.Steps.Selection(approximating: JPY(minorUnits: 5), in: try (JPY.zero ... JPY(minorUnits: 10)).steps(by: .minorUnit)))

        #expect(runtime.amount == Money(typed.amount))
        #expect(runtime.index == 2)
        #expect(try Credits.Steps.Selection(runtime) == typed)
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .jpy)) { try GBP.Steps.Selection(yen) }
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: Millicredits.currency)) {
            try GBP.Steps.Selection(runtime)
        }
    }
}
