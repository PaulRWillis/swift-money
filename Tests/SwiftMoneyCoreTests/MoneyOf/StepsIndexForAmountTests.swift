import SwiftMoneyCore
import Testing

private typealias Credits = MoneyOf<Millicredits>
private typealias RoundingError = MoneyStepsRoundingError<Currencies.GBP>
private typealias RuntimeRoundingError = MoneyStepsRoundingError<AnyCurrency>

private func pounds(_ minorUnits: Int64) -> GBP {
    GBP(minorUnits: minorUnits)
}

// £10, £110, £210 and £250: whole gaps of £100, then a shorter last gap of £40.
private func tenToTwoFifty() throws -> GBP.Steps {
    try (pounds(10_00) ... pounds(250_00)).steps(by: .majorUnits(100))
}

private let everyRule: [DirectedRoundingRule] = [.down, .up, .towardZero, .awayFromZero]

private let everyTie: [TieBreakingRule] = [.even, .awayFromZero]

// The step a rule rounds an amount to, or nil when no step satisfies the rule.
private func rounded(_ amount: GBP, onto steps: GBP.Steps, by rule: DirectedRoundingRule) -> GBP? {
    do throws(RoundingError) {
        return steps[try steps.index(approximating: amount, rounding: rule)]
    } catch {
        switch error {
        case .outOfBounds: return nil
        }
    }
}

// The step a runtime amount rounds to by a rule, or nil when no step satisfies the rule.
private func rounded(
    _ amount: Money,
    onto steps: Money.Steps,
    by rule: DirectedRoundingRule
) throws(RuntimeRoundingError) -> Money? {
    do throws(RuntimeRoundingError) {
        return steps[try steps.index(approximating: amount, rounding: rule)]
    } catch .outOfBounds {
        return nil
    }
}

// The step nearest an amount, a tie broken as given.
private func nearest(_ amount: GBP, onto steps: GBP.Steps, tiesTo tie: TieBreakingRule = .even) -> GBP {
    steps[steps.index(approximating: amount, tiesTo: tie)]
}

@Suite("MoneyOf.Steps.index(approximating:)")
struct StepsIndexForAmountTests {

    @Test("An amount on a step is that step under every directed rule", arguments: everyRule)
    func onAStep(_ rule: DirectedRoundingRule) throws {
        let steps = try tenToTwoFifty()

        #expect(try steps.index(approximating: pounds(10_00), rounding: rule) == 0)
        #expect(try steps.index(approximating: pounds(110_00), rounding: rule) == 1)
        #expect(try steps.index(approximating: pounds(250_00), rounding: rule) == 3)
    }

    @Test("An amount on a step is that step under every tie-break", arguments: everyTie)
    func onAStepNearest(_ tie: TieBreakingRule) throws {
        let steps = try tenToTwoFifty()

        #expect(steps.index(approximating: pounds(10_00), tiesTo: tie) == 0)
        #expect(steps.index(approximating: pounds(110_00), tiesTo: tie) == 1)
        #expect(steps.index(approximating: pounds(250_00), tiesTo: tie) == 3)
    }

    @Test("Beyond the steps, up above the highest and down below the lowest throw outOfBounds")
    func outsideWithNoStepOnTheRuleSideThrows() throws {
        let steps = try tenToTwoFifty()
        let down = try (pounds(10_00) ... pounds(250_00)).steps(by: .majorUnits(-100))

        #expect(throws: RoundingError.outOfBounds) { try steps.index(approximating: pounds(300_00), rounding: .up) }
        #expect(throws: RoundingError.outOfBounds) { try steps.index(approximating: pounds(5_00), rounding: .down) }
        #expect(throws: RoundingError.outOfBounds) { try steps.index(approximating: GBP.max, rounding: .up) }
        #expect(throws: RoundingError.outOfBounds) { try down.index(approximating: GBP.min, rounding: .down) }
        #expect(throws: RoundingError.outOfBounds) { try down.index(approximating: pounds(300_00), rounding: .up) }
    }

    @Test("Beyond the steps, up below the lowest and down above the highest take the nearer end")
    func outsideWithAStepOnTheRuleSide() throws {
        let steps = try tenToTwoFifty()
        let down = try (pounds(10_00) ... pounds(250_00)).steps(by: .majorUnits(-100))

        #expect(try steps.index(approximating: pounds(5_00), rounding: .up) == 0)
        #expect(try steps.index(approximating: pounds(300_00), rounding: .down) == 3)
        #expect(try down.index(approximating: GBP.min, rounding: .up) == 3)
        #expect(try down.index(approximating: pounds(300_00), rounding: .down) == 0)
    }

    @Test("Beyond the steps, toward and away from zero act as down or up by the amount's sign")
    func outsideTowardAndAwayFromZero() throws {
        let positive = try (pounds(5_00) ... pounds(17_00)).steps(by: .majorUnits(12))
        let negative = try (pounds(-17_00) ... pounds(-5_00)).steps(by: .majorUnits(12))

        #expect(positive.map(\.minorUnits) == [5_00, 17_00])
        #expect(rounded(pounds(-3_00), onto: positive, by: .towardZero) == pounds(5_00))
        #expect(throws: RoundingError.outOfBounds) {
            try positive.index(approximating: pounds(-3_00), rounding: .awayFromZero)
        }
        #expect(rounded(pounds(3_00), onto: positive, by: .awayFromZero) == pounds(5_00))
        #expect(rounded(pounds(3_00), onto: positive, by: .towardZero) == nil)
        #expect(rounded(pounds(20_00), onto: positive, by: .towardZero) == pounds(17_00))
        #expect(rounded(pounds(20_00), onto: positive, by: .awayFromZero) == nil)
        #expect(rounded(pounds(-3_00), onto: negative, by: .awayFromZero) == pounds(-5_00))
        #expect(rounded(pounds(-3_00), onto: negative, by: .towardZero) == nil)
        #expect(rounded(.zero, onto: negative, by: .towardZero) == pounds(-5_00))
        #expect(rounded(.zero, onto: negative, by: .awayFromZero) == nil)
    }

    @Test("Beyond the steps, the nearest step is the nearer end under every tie-break", arguments: everyTie)
    func outsideNearestIsTheNearerEnd(_ tie: TieBreakingRule) throws {
        let steps = try tenToTwoFifty()
        let down = try (pounds(10_00) ... pounds(250_00)).steps(by: .majorUnits(-100))

        #expect(steps.index(approximating: pounds(5_00), tiesTo: tie) == 0)
        #expect(steps.index(approximating: pounds(300_00), tiesTo: tie) == 3)
        #expect(steps.index(approximating: GBP.min, tiesTo: tie) == 0)
        #expect(steps.index(approximating: GBP.max, tiesTo: tie) == 3)
        #expect(down.index(approximating: pounds(5_00), tiesTo: tie) == 3)
        #expect(down.index(approximating: pounds(300_00), tiesTo: tie) == 0)
    }

    @Test("Between two steps, each directed rule picks the step its name says")
    func betweenTwoSteps() throws {
        let steps = try tenToTwoFifty()
        let nearerLower = pounds(130_00)
        let nearerUpper = pounds(190_00)

        #expect(try steps.index(approximating: nearerLower, rounding: .down) == 1)
        #expect(try steps.index(approximating: nearerLower, rounding: .up) == 2)
        #expect(try steps.index(approximating: nearerLower, rounding: .towardZero) == 1)
        #expect(try steps.index(approximating: nearerLower, rounding: .awayFromZero) == 2)
        #expect(try steps.index(approximating: nearerUpper, rounding: .down) == 1)
        #expect(try steps.index(approximating: nearerUpper, rounding: .up) == 2)
    }

    @Test("Between two steps, the nearer is taken under every tie-break", arguments: everyTie)
    func betweenTwoStepsNearest(_ tie: TieBreakingRule) throws {
        let steps = try tenToTwoFifty()

        #expect(steps.index(approximating: pounds(130_00), tiesTo: tie) == 1)
        #expect(steps.index(approximating: pounds(190_00), tiesTo: tie) == 2)
    }

    @Test("By default, a tie goes to an even position from the lower bound")
    func defaultTieIsToEven() throws {
        let steps = try tenToTwoFifty()

        #expect(steps.index(approximating: pounds(60_00)) == 0)
        #expect(steps.index(approximating: pounds(60_00), tiesTo: .even) == 0)
        #expect(steps.index(approximating: pounds(60_00), tiesTo: .awayFromZero) == 1)
        #expect(steps.index(approximating: pounds(90_00)) == 1)
    }

    @Test("Ties go to an even position from the lower bound, or away from zero")
    func ties() throws {
        let steps = try tenToTwoFifty()
        let negative = try (pounds(-250_00) ... pounds(-10_00)).steps(by: .majorUnits(100))

        #expect(steps.index(approximating: pounds(160_00), tiesTo: .even) == 2)
        #expect(steps.index(approximating: pounds(160_00), tiesTo: .awayFromZero) == 2)
        #expect(steps.index(approximating: pounds(60_00), tiesTo: .even) == 0)
        #expect(negative.map(\.minorUnits) == [-250_00, -150_00, -50_00, -10_00])
        #expect(negative.index(approximating: pounds(-100_00), tiesTo: .even) == 2)
        #expect(negative.index(approximating: pounds(-100_00), tiesTo: .awayFromZero) == 1)
    }

    @Test("The shorter last gap is measured as it is, not as a whole stride")
    func shorterLastGap() throws {
        let steps = try tenToTwoFifty()

        #expect(steps.index(approximating: pounds(235_00)) == 3)
        #expect(steps.index(approximating: pounds(225_00)) == 2)
        #expect(steps.index(approximating: pounds(230_00), tiesTo: .even) == 2)
        #expect(steps.index(approximating: pounds(230_00), tiesTo: .awayFromZero) == 3)
    }

    @Test("Toward and away from zero follow the amount's sign when both neighbors share it")
    func towardAndAwayFromZeroBySign() throws {
        let negative = try (pounds(-250_00) ... pounds(-10_00)).steps(by: .majorUnits(100))

        #expect(try negative.index(approximating: pounds(-130_00), rounding: .towardZero) == 2)
        #expect(try negative.index(approximating: pounds(-130_00), rounding: .awayFromZero) == 1)
        #expect(try negative.index(approximating: pounds(-130_00), rounding: .down) == 1)
        #expect(try negative.index(approximating: pounds(-130_00), rounding: .up) == 2)
    }

    @Test("Neighbors either side of zero: toward zero takes the smaller step, away from zero the larger")
    func towardAndAwayFromZeroBySizeAcrossZero() throws {
        let straddling = try (pounds(-7_00) ... pounds(17_00)).steps(by: .majorUnits(12))
        let unequal = try (pounds(-10_00) ... pounds(10_00)).steps(by: .majorUnits(15))

        #expect(straddling.map(\.minorUnits) == [-7_00, 5_00, 17_00])
        #expect(try straddling.index(approximating: pounds(3_00), rounding: .towardZero) == 1)
        #expect(try straddling.index(approximating: pounds(3_00), rounding: .awayFromZero) == 0)
        #expect(try straddling.index(approximating: pounds(-3_00), rounding: .towardZero) == 1)
        #expect(try straddling.index(approximating: pounds(-3_00), rounding: .awayFromZero) == 0)
        #expect(unequal.map(\.minorUnits) == [-10_00, 5_00, 10_00])
        #expect(try unequal.index(approximating: .zero, rounding: .towardZero) == 1)
        #expect(try unequal.index(approximating: .zero, rounding: .awayFromZero) == 0)
    }

    @Test("Neighbors of equal size either side of zero: toward and away from zero keep the amount's sign")
    func towardAndAwayFromZeroEqualSizeAcrossZero() throws {
        let steps = try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(20))

        #expect(steps.map(\.minorUnits) == [-50_00, -30_00, -10_00, 10_00, 30_00, 50_00])
        #expect(try steps.index(approximating: pounds(3_00), rounding: .towardZero) == 3)
        #expect(try steps.index(approximating: pounds(3_00), rounding: .awayFromZero) == 3)
        #expect(try steps.index(approximating: pounds(-3_00), rounding: .towardZero) == 2)
        #expect(try steps.index(approximating: pounds(-3_00), rounding: .awayFromZero) == 2)
        #expect(try steps.index(approximating: .zero, rounding: .towardZero) == 3)
        #expect(try steps.index(approximating: .zero, rounding: .awayFromZero) == 3)
    }

    @Test("Across zero, down, up and both tie-breaks are unchanged by size")
    func otherRulesAcrossZero() throws {
        let equal = try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(20))
        let straddling = try (pounds(-7_00) ... pounds(17_00)).steps(by: .majorUnits(12))

        #expect(try equal.index(approximating: pounds(3_00), rounding: .down) == 2)
        #expect(try equal.index(approximating: pounds(-3_00), rounding: .up) == 3)
        #expect(equal.index(approximating: .zero, tiesTo: .awayFromZero) == 3)
        #expect(equal.index(approximating: .zero, tiesTo: .even) == 2)
        #expect(straddling.index(approximating: pounds(-1_00), tiesTo: .awayFromZero) == 0)
        #expect(straddling.index(approximating: pounds(-1_00), tiesTo: .even) == 0)
        #expect(straddling.index(approximating: pounds(3_00), tiesTo: .even) == 1)
    }

    @Test("Descending steps across zero pick the same amounts by size")
    func acrossZeroDescending() throws {
        let equal = try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(-20))
        let straddling = try (pounds(-7_00) ... pounds(17_00)).steps(by: .majorUnits(-12))

        #expect(equal.map(\.minorUnits) == [50_00, 30_00, 10_00, -10_00, -30_00, -50_00])
        #expect(rounded(pounds(3_00), onto: equal, by: .towardZero) == pounds(10_00))
        #expect(rounded(pounds(3_00), onto: equal, by: .awayFromZero) == pounds(10_00))
        #expect(rounded(pounds(-3_00), onto: equal, by: .towardZero) == pounds(-10_00))
        #expect(rounded(pounds(-3_00), onto: equal, by: .awayFromZero) == pounds(-10_00))
        #expect(straddling.map(\.minorUnits) == [17_00, 5_00, -7_00])
        #expect(rounded(pounds(3_00), onto: straddling, by: .towardZero) == pounds(5_00))
        #expect(rounded(pounds(3_00), onto: straddling, by: .awayFromZero) == pounds(-7_00))
        #expect(nearest(pounds(-1_00), onto: straddling, tiesTo: .awayFromZero) == pounds(-7_00))
        #expect(nearest(.zero, onto: equal, tiesTo: .awayFromZero) == pounds(10_00))
    }

    @Test("Runtime steps across zero round by size as typed ones do")
    func acrossZeroRuntime() throws {
        let equal = Money.Steps(try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(20)))
        let straddling = Money.Steps(try (pounds(-7_00) ... pounds(17_00)).steps(by: .majorUnits(-12)))

        #expect(try rounded(Money(pounds(3_00)), onto: equal, by: .towardZero) == Money(pounds(10_00)))
        #expect(try rounded(Money(pounds(-3_00)), onto: equal, by: .awayFromZero) == Money(pounds(-10_00)))
        #expect(try rounded(Money(pounds(3_00)), onto: straddling, by: .towardZero) == Money(pounds(5_00)))
        #expect(try rounded(Money(pounds(-3_00)), onto: straddling, by: .awayFromZero) == Money(pounds(-7_00)))
        #expect(try straddling[straddling.index(approximating: Money(pounds(-1_00)), tiesTo: .awayFromZero)] == Money(pounds(-7_00)))
    }

    @Test("A tie goes to the step at an even position from the lower bound, whichever way the steps run")
    func tiesCountFromTheLowerBound() throws {
        let even = pounds(0) ... pounds(300_00)
        let evenDown = try even.steps(by: .majorUnits(-100))
        let oddDown = try (pounds(0) ... pounds(400_00)).steps(by: .majorUnits(-100))
        let shorterLastGapDown = try (pounds(10_00) ... pounds(250_00)).steps(by: .majorUnits(-100))
        let acrossZeroDown = try (pounds(-50_00) ... pounds(50_00)).steps(by: .majorUnits(-20))

        #expect(nearest(pounds(50_00), onto: try even.steps(by: .majorUnits(100))) == pounds(0))
        #expect(nearest(pounds(50_00), onto: evenDown) == pounds(0))
        #expect(nearest(pounds(150_00), onto: evenDown) == pounds(200_00))
        #expect(nearest(pounds(250_00), onto: evenDown) == pounds(200_00))
        #expect(nearest(pounds(50_00), onto: oddDown) == pounds(0))
        #expect(nearest(pounds(150_00), onto: oddDown) == pounds(200_00))
        #expect(shorterLastGapDown.map(\.minorUnits) == [250_00, 150_00, 50_00, 10_00])
        #expect(nearest(pounds(100_00), onto: shorterLastGapDown) == pounds(150_00))
        #expect(nearest(.zero, onto: acrossZeroDown) == pounds(-10_00))
    }

    @Test("Descending steps on the same amounts pick the same amount as ascending ones", arguments: everyRule)
    func descendingPicksTheSameAmount(_ rule: DirectedRoundingRule) throws {
        for (up, down) in try ascendingAndDescending() {
            #expect(Array(up) == Array(down.reversed()))
            for probe in sameAmountProbes {
                #expect(rounded(probe, onto: down, by: rule) == rounded(probe, onto: up, by: rule), "\(probe)")
            }
        }
    }

    @Test("Descending steps on the same amounts pick the same nearest amount as ascending ones", arguments: everyTie)
    func descendingPicksTheSameNearestAmount(_ tie: TieBreakingRule) throws {
        for (up, down) in try ascendingAndDescending() {
            for probe in sameAmountProbes {
                #expect(nearest(probe, onto: down, tiesTo: tie) == nearest(probe, onto: up, tiesTo: tie), "\(probe)")
            }
        }
    }

    @Test("Yen and a custom currency round in their own minor units")
    func yenAndCustomCurrency() throws {
        let yen = try (JPY(minorUnits: 0) ... JPY(minorUnits: 1_000)).steps(by: .majorUnits(300))
        let credits = try (Credits(minorUnits: 0) ... Credits(minorUnits: 5_000)).steps(by: .majorUnits(2))

        #expect(yen.map(\.minorUnits) == [0, 300, 600, 900, 1_000])
        #expect(yen.index(approximating: JPY(minorUnits: 950)) == 4)
        #expect(try yen.index(approximating: JPY(minorUnits: 301), rounding: .up) == 2)
        #expect(credits.map(\.minorUnits) == [0, 2_000, 4_000, 5_000])
        #expect(credits.index(approximating: Credits(minorUnits: 3_000)) == 2)
        #expect(credits.index(approximating: Credits(minorUnits: 3_000), tiesTo: .awayFromZero) == 2)
        #expect(try credits.index(approximating: Credits(minorUnits: 3_999), rounding: .down) == 1)
    }

    @Test("Runtime steps find the same position as typed ones, and throw where they do")
    func runtimeMatchesTyped() throws {
        let typed = try tenToTwoFifty()
        let runtime = Money.Steps(typed)

        for rule in everyRule {
            for probe in [5_00, 60_00, 130_00, 235_00, 300_00].map(pounds) {
                let expected = rounded(probe, onto: typed, by: rule).map { Money($0) }
                #expect(try rounded(Money(probe), onto: runtime, by: rule) == expected, "\(probe) by \(rule)")
            }
        }
        for tie in everyTie {
            for probe in [5_00, 60_00, 230_00, 300_00].map(pounds) {
                let expected = Money(nearest(probe, onto: typed, tiesTo: tie))
                #expect(try runtime[runtime.index(approximating: Money(probe), tiesTo: tie)] == expected, "\(probe)")
            }
        }
        #expect(try runtime.index(approximating: Money(pounds(60_00))) == 0)
        #expect(typed.index(approximating: pounds(60_00)) == 0)
    }

    @Test("To the nearest step, a runtime amount in another currency throws MoneyError, the steps' currency first", arguments: everyTie)
    func runtimeMismatchNearest(_ tie: TieBreakingRule) throws {
        let runtime = Money.Steps(try tenToTwoFifty())

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try runtime.index(approximating: Money(minorUnits: 60_00, currency: .eur), tiesTo: tie)
        }
        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try runtime.index(approximating: Money(minorUnits: 60_00, currency: .eur))
        }
    }

    @Test("With a rule, a runtime amount in another currency throws a mismatch with its currency, checked first")
    func runtimeMismatchWithARule() throws {
        let runtime = Money.Steps(try tenToTwoFifty())
        let credits = Money.Steps(try (Credits.zero ... Credits(minorUnits: 5_000)).steps(by: .majorUnit))

        #expect(throws: RuntimeRoundingError.currencyMismatch(.gbp)) {
            try credits.index(approximating: Money(minorUnits: 1_000, currency: .gbp), rounding: .down)
        }
        #expect(throws: RuntimeRoundingError.currencyMismatch(.eur)) {
            try runtime.index(approximating: Money(minorUnits: 300_00, currency: .eur), rounding: .up)
        }
        #expect(throws: RuntimeRoundingError.outOfBounds) {
            try runtime.index(approximating: Money(pounds(300_00)), rounding: .up)
        }
    }
}

// Ascending and descending steps on the same amounts: odd and even counts, and either side of zero.
private func ascendingAndDescending() throws -> [(GBP.Steps, GBP.Steps)] {
    let odd = pounds(0) ... pounds(400_00)
    let even = pounds(0) ... pounds(300_00)
    let oddAcrossZero = pounds(-40_00) ... pounds(40_00)
    let evenAcrossZero = pounds(-50_00) ... pounds(50_00)

    return [
        (try odd.steps(by: .majorUnits(100)), try odd.steps(by: .majorUnits(-100))),
        (try even.steps(by: .majorUnits(100)), try even.steps(by: .majorUnits(-100))),
        (try oddAcrossZero.steps(by: .majorUnits(20)), try oddAcrossZero.steps(by: .majorUnits(-20))),
        (try evenAcrossZero.steps(by: .majorUnits(20)), try evenAcrossZero.steps(by: .majorUnits(-20))),
    ]
}

private let sameAmountProbes = [
    -60_00, -50_00, -40_00, -30_00, -20_00, -10_00, -3_00, -1_00, 0, 1_00, 3_00, 10_00, 20_00,
    30_00, 50_00, 70_00, 150_00, 250_00, 299_99, 399_99, 500_00,
].map(pounds)
