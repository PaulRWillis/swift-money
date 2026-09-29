import SwiftMoneyCore
import Testing

private typealias Credits = MoneyOf<Millicredits>

private func pounds(_ minorUnits: Int64) -> GBP {
    GBP(minorUnits: minorUnits)
}

// £10, £110, £210 and £250: whole gaps of £100, then a shorter last gap of £40.
private func tenToTwoFifty() throws -> GBP.Steps {
    try (pounds(10_00) ... pounds(250_00)).steps(by: .majorUnits(100))
}

private let everyRule: [RoundingRule] = [
    .down, .up, .towardZero, .awayFromZero, .toNearestOrEven, .toNearestOrAwayFromZero,
]

@Suite("MoneyOf.Steps.index(for:rounding:)")
struct StepsIndexForAmountTests {

    @Test("An amount on a step is that step under every rule", arguments: everyRule)
    func onAStep(_ rule: RoundingRule) throws {
        let steps = try tenToTwoFifty()

        #expect(steps.index(for: pounds(10_00), rounding: rule) == 0)
        #expect(steps.index(for: pounds(110_00), rounding: rule) == 1)
        #expect(steps.index(for: pounds(250_00), rounding: rule) == 3)
    }

    @Test("An amount outside the steps is the nearer end under every rule", arguments: everyRule)
    func outsideIsTheNearerEnd(_ rule: RoundingRule) throws {
        let steps = try tenToTwoFifty()
        let down = try (pounds(10_00) ... pounds(250_00)).steps(by: .majorUnits(-100))

        #expect(steps.index(for: pounds(5_00), rounding: rule) == 0)
        #expect(steps.index(for: pounds(300_00), rounding: rule) == 3)
        #expect(steps.index(for: GBP.min, rounding: rule) == 0)
        #expect(steps.index(for: GBP.max, rounding: rule) == 3)
        #expect(down.index(for: pounds(5_00), rounding: rule) == 3)
        #expect(down.index(for: pounds(300_00), rounding: rule) == 0)
    }

    @Test("Between two steps, each rule picks the step its name says")
    func betweenTwoSteps() throws {
        let steps = try tenToTwoFifty()
        let nearerLower = pounds(130_00)
        let nearerUpper = pounds(190_00)

        #expect(steps.index(for: nearerLower, rounding: .down) == 1)
        #expect(steps.index(for: nearerLower, rounding: .up) == 2)
        #expect(steps.index(for: nearerLower, rounding: .towardZero) == 1)
        #expect(steps.index(for: nearerLower, rounding: .awayFromZero) == 2)
        #expect(steps.index(for: nearerLower, rounding: .toNearestOrEven) == 1)
        #expect(steps.index(for: nearerLower, rounding: .toNearestOrAwayFromZero) == 1)
        #expect(steps.index(for: nearerUpper, rounding: .down) == 1)
        #expect(steps.index(for: nearerUpper, rounding: .up) == 2)
        #expect(steps.index(for: nearerUpper, rounding: .toNearestOrEven) == 2)
        #expect(steps.index(for: nearerUpper, rounding: .toNearestOrAwayFromZero) == 2)
    }

    @Test("The default rule is to the nearest step, ties to the even index")
    func defaultIsToNearestOrEven() throws {
        let steps = try tenToTwoFifty()

        #expect(steps.index(for: pounds(60_00)) == 0)
        #expect(steps.index(for: pounds(60_00), rounding: .toNearestOrAwayFromZero) == 1)
        #expect(steps.index(for: pounds(90_00)) == 1)
    }

    @Test("A tie goes to the even index, or with toNearestOrAwayFromZero to the step farther from zero")
    func ties() throws {
        let steps = try tenToTwoFifty()
        let negative = try (pounds(-250_00) ... pounds(-10_00)).steps(by: .majorUnits(100))

        #expect(steps.index(for: pounds(160_00), rounding: .toNearestOrEven) == 2)
        #expect(steps.index(for: pounds(160_00), rounding: .toNearestOrAwayFromZero) == 2)
        #expect(steps.index(for: pounds(60_00), rounding: .toNearestOrEven) == 0)
        #expect(negative.map(\.minorUnits) == [-250_00, -150_00, -50_00, -10_00])
        #expect(negative.index(for: pounds(-100_00), rounding: .toNearestOrEven) == 2)
        #expect(negative.index(for: pounds(-100_00), rounding: .toNearestOrAwayFromZero) == 1)
    }

    @Test("The shorter last gap is measured as it is, not as a whole stride")
    func shorterLastGap() throws {
        let steps = try tenToTwoFifty()

        #expect(steps.index(for: pounds(235_00)) == 3)
        #expect(steps.index(for: pounds(225_00)) == 2)
        #expect(steps.index(for: pounds(230_00), rounding: .toNearestOrEven) == 2)
        #expect(steps.index(for: pounds(230_00), rounding: .toNearestOrAwayFromZero) == 3)
    }

    @Test("Toward and away from zero follow the amount's sign when both neighbors share it")
    func towardAndAwayFromZeroBySign() throws {
        let negative = try (pounds(-250_00) ... pounds(-10_00)).steps(by: .majorUnits(100))

        #expect(negative.index(for: pounds(-130_00), rounding: .towardZero) == 2)
        #expect(negative.index(for: pounds(-130_00), rounding: .awayFromZero) == 1)
        #expect(negative.index(for: pounds(-130_00), rounding: .down) == 1)
        #expect(negative.index(for: pounds(-130_00), rounding: .up) == 2)
    }

    @Test("Neighbors either side of zero: toward zero takes the smaller step, away from zero the larger")
    func towardAndAwayFromZeroBySizeAcrossZero() throws {
        let straddling = try (pounds(-7_00) ... pounds(17_00)).steps(by: .majorUnits(12))
        let unequal = try (pounds(-10_00) ... pounds(10_00)).steps(by: .majorUnits(15))

        #expect(straddling.map(\.minorUnits) == [-7_00, 5_00, 17_00])
        #expect(straddling.index(for: pounds(3_00), rounding: .towardZero) == 1)
        #expect(straddling.index(for: pounds(3_00), rounding: .awayFromZero) == 0)
        #expect(straddling.index(for: pounds(-3_00), rounding: .towardZero) == 1)
        #expect(straddling.index(for: pounds(-3_00), rounding: .awayFromZero) == 0)
        #expect(unequal.map(\.minorUnits) == [-10_00, 5_00, 10_00])
        #expect(unequal.index(for: .zero, rounding: .towardZero) == 1)
        #expect(unequal.index(for: .zero, rounding: .awayFromZero) == 0)
    }

    @Test("Neighbors of equal size either side of zero: toward and away from zero keep the amount's sign")
    func towardAndAwayFromZeroEqualSizeAcrossZero() throws {
        let steps = try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(20))

        #expect(steps.map(\.minorUnits) == [-50_00, -30_00, -10_00, 10_00, 30_00, 50_00])
        #expect(steps.index(for: pounds(3_00), rounding: .towardZero) == 3)
        #expect(steps.index(for: pounds(3_00), rounding: .awayFromZero) == 3)
        #expect(steps.index(for: pounds(-3_00), rounding: .towardZero) == 2)
        #expect(steps.index(for: pounds(-3_00), rounding: .awayFromZero) == 2)
        #expect(steps.index(for: .zero, rounding: .towardZero) == 3)
        #expect(steps.index(for: .zero, rounding: .awayFromZero) == 3)
    }

    @Test("Across zero, down, up and both nearest rules are unchanged by size")
    func otherRulesAcrossZero() throws {
        let equal = try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(20))
        let straddling = try (pounds(-7_00) ... pounds(17_00)).steps(by: .majorUnits(12))

        #expect(equal.index(for: pounds(3_00), rounding: .down) == 2)
        #expect(equal.index(for: pounds(-3_00), rounding: .up) == 3)
        #expect(equal.index(for: .zero, rounding: .toNearestOrAwayFromZero) == 3)
        #expect(straddling.index(for: pounds(-1_00), rounding: .toNearestOrAwayFromZero) == 0)
        #expect(straddling.index(for: pounds(3_00), rounding: .toNearestOrEven) == 1)
    }

    @Test("Descending steps across zero pick the same amounts by size")
    func acrossZeroDescending() throws {
        let equal = try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(-20))
        let straddling = try (pounds(-7_00) ... pounds(17_00)).steps(by: .majorUnits(-12))

        #expect(equal.map(\.minorUnits) == [50_00, 30_00, 10_00, -10_00, -30_00, -50_00])
        #expect(equal[equal.index(for: pounds(3_00), rounding: .towardZero)] == pounds(10_00))
        #expect(equal[equal.index(for: pounds(3_00), rounding: .awayFromZero)] == pounds(10_00))
        #expect(equal[equal.index(for: pounds(-3_00), rounding: .towardZero)] == pounds(-10_00))
        #expect(equal[equal.index(for: pounds(-3_00), rounding: .awayFromZero)] == pounds(-10_00))
        #expect(straddling.map(\.minorUnits) == [17_00, 5_00, -7_00])
        #expect(straddling[straddling.index(for: pounds(3_00), rounding: .towardZero)] == pounds(5_00))
        #expect(straddling[straddling.index(for: pounds(3_00), rounding: .awayFromZero)] == pounds(-7_00))
    }

    @Test("Runtime steps across zero round by size as typed ones do")
    func acrossZeroRuntime() throws {
        let equal = Money.Steps(try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(20)))
        let straddling = Money.Steps(try (pounds(-7_00) ... pounds(17_00)).steps(by: .majorUnits(-12)))

        #expect(try equal[equal.index(for: Money(pounds(3_00)), rounding: .towardZero)] == Money(pounds(10_00)))
        #expect(try equal[equal.index(for: Money(pounds(-3_00)), rounding: .awayFromZero)] == Money(pounds(-10_00)))
        #expect(try straddling[straddling.index(for: Money(pounds(3_00)), rounding: .towardZero)] == Money(pounds(5_00)))
        #expect(try straddling[straddling.index(for: Money(pounds(-3_00)), rounding: .awayFromZero)] == Money(pounds(-7_00)))
    }

    // An odd count keeps an index's parity when the order reverses, so even ties agree too.
    @Test("Descending steps on the same amounts pick the same amount as ascending ones", arguments: everyRule)
    func descendingPicksTheSameAmount(_ rule: RoundingRule) throws {
        let range = pounds(0) ... pounds(400_00)
        let up = try range.steps(by: .majorUnits(100))
        let down = try range.steps(by: .majorUnits(-100))
        let probes = [-1_00, 0, 30_00, 50_00, 70_00, 150_00, 250_00, 399_99, 500_00].map(pounds)

        for probe in probes {
            #expect(down[down.index(for: probe, rounding: rule)] == up[up.index(for: probe, rounding: rule)])
        }
    }

    @Test("Yen and a custom currency round in their own minor units")
    func yenAndCustomCurrency() throws {
        let yen = try (JPY(minorUnits: 0) ... JPY(minorUnits: 1_000)).steps(by: .majorUnits(300))
        let credits = try (Credits(minorUnits: 0) ... Credits(minorUnits: 5_000)).steps(by: .majorUnits(2))

        #expect(yen.map(\.minorUnits) == [0, 300, 600, 900, 1_000])
        #expect(yen.index(for: JPY(minorUnits: 950)) == 4)
        #expect(yen.index(for: JPY(minorUnits: 301), rounding: .up) == 2)
        #expect(credits.map(\.minorUnits) == [0, 2_000, 4_000, 5_000])
        #expect(credits.index(for: Credits(minorUnits: 3_000)) == 2)
        #expect(credits.index(for: Credits(minorUnits: 3_999), rounding: .down) == 1)
    }

    @Test("Runtime steps find the same position as typed ones")
    func runtimeMatchesTyped() throws {
        let typed = try tenToTwoFifty()
        let runtime = Money.Steps(typed)

        for rule in everyRule {
            for probe in [5_00, 60_00, 130_00, 235_00, 300_00].map(pounds) {
                let runtimeIndex = try runtime.index(for: Money(probe), rounding: rule)
                #expect(runtime[runtimeIndex] == Money(typed[typed.index(for: probe, rounding: rule)]))
            }
        }
        #expect(try runtime.index(for: Money(minorUnits: 60_00, currency: .gbp)) == 0)
    }

    @Test("A runtime amount in another currency throws a mismatch, the steps' currency first")
    func runtimeMismatch() throws {
        let runtime = Money.Steps(try tenToTwoFifty())
        let credits = Money.Steps(try (Credits.zero ... Credits(minorUnits: 5_000)).steps(by: .majorUnit))

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try runtime.index(for: Money(minorUnits: 60_00, currency: .eur))
        }
        #expect(throws: MoneyError.currencyMismatch(lhs: Millicredits.currency, rhs: .gbp)) {
            try credits.index(for: Money(minorUnits: 1_000, currency: .gbp), rounding: .down)
        }
    }
}
