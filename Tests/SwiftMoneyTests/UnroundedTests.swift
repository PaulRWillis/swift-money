import SwiftMoney
import Testing

@Suite("Unrounded Tests")
struct UnroundedTests {

    // MARK: - The reason the type exists

    @Test("A chain settles once, where scaling settles at every step")
    func aChainSettlesOnce() {
        let chained = GBP(minorUnits: 10_00).unrounded * Ratio(1, 3) * Ratio(3, 1)
        let scaledTwice = GBP(minorUnits: 10_00)
            .scaled(by: Ratio(1, 3), rounding: .toNearestOrEven)
            .scaled(by: Ratio(3, 1), rounding: .toNearestOrEven)

        #expect(chained.rounded(.toNearestOrEven) == GBP(minorUnits: 10_00))
        #expect(scaledTwice == GBP(minorUnits: 9_99))
    }

    // The example the type's own documentation gives: 4.5% a year accrued over 31 days on £10,000.
    @Test("Two rates chain into one settlement")
    func twoRatesChain() {
        let interest = GBP(minorUnits: 10_000_00).unrounded * Ratio(45, 1000) * Ratio(31, 365)

        #expect(interest.rounded(.toNearestOrEven) == GBP(minorUnits: 38_22))
    }

    // MARK: - Entry

    @Test("An amount survives a round trip", arguments: everyRule)
    func roundTrip(rule: RoundingRule) {
        #expect(GBP(minorUnits: 12_34).unrounded.rounded(rule) == GBP(minorUnits: 12_34))
        #expect(GBP(minorUnits: -12_34).unrounded.rounded(rule) == GBP(minorUnits: -12_34))
        #expect(GBP.zero.unrounded.rounded(rule) == GBP.zero)
    }

    // MARK: - Multiplication

    @Test("A ratio scales an amount")
    func ratioScales() {
        #expect(roundsIdentically(GBP(minorUnits: 9_99).unrounded * Ratio(1, 3)) == GBP(minorUnits: 3_33))
    }

    @Test("A ratio scales an amount from either side")
    func ratioScalesFromEitherSide() {
        let ratio = Ratio(1, 3)

        #expect(GBP(minorUnits: 9_99).unrounded * ratio == ratio * GBP(minorUnits: 9_99).unrounded)
    }

    // `Ratio` is deliberately not `ExpressibleByIntegerLiteral`, which is what keeps this unambiguous.
    @Test("A whole number scales an amount from either side")
    func wholeNumberScales() {
        #expect(roundsIdentically(GBP(minorUnits: 1_00).unrounded * 3) == GBP(minorUnits: 3_00))
        #expect(roundsIdentically(3 * GBP(minorUnits: 1_00).unrounded) == GBP(minorUnits: 3_00))
    }

    @Test("Scaling in place matches scaling")
    func scalingInPlace() {
        var byRatio = GBP(minorUnits: 9_99).unrounded
        byRatio *= Ratio(1, 3)

        var byWholeNumber = GBP(minorUnits: 1_00).unrounded
        byWholeNumber *= 3

        #expect(byRatio == GBP(minorUnits: 9_99).unrounded * Ratio(1, 3))
        #expect(byWholeNumber == GBP(minorUnits: 1_00).unrounded * 3)
    }

    @Test("Scaling by zero is zero", arguments: everyRule)
    func scalingByZero(rule: RoundingRule) {
        #expect((GBP(minorUnits: 10_00).unrounded * Ratio(0, 1)).rounded(rule) == GBP.zero)
    }

    @Test("A chain keeps a fraction no single step could")
    func aChainKeepsAFraction() {
        let third = GBP(minorUnits: 10_00).unrounded * Ratio(1, 3)

        #expect(third.rounded(.towardZero) == GBP(minorUnits: 3_33))
        #expect(third.rounded(.awayFromZero) == GBP(minorUnits: 3_34))
    }

    // MARK: - Exactness

    @Test("An exact chain rounds the same way under every rule")
    func anExactChainIsIndifferentToRule() {
        #expect(roundsIdentically(GBP(minorUnits: 30_00).unrounded * Ratio(18, 30) * Ratio(11, 18)) == GBP(minorUnits: 11_00))
    }

    @Test("An inexact chain does not round the same way under every rule")
    func anInexactChainIsNotIndifferentToRule() {
        #expect(roundsIdentically(GBP(minorUnits: 10_00).unrounded * Ratio(1, 3)) == nil)
    }

    // MARK: - Overflow

    // Naively this multiplies the largest amount by three, which does not fit. Cancelling it against
    // the denominator first leaves three over one.
    @Test("A product that cancels does not overflow")
    func aProductThatCancelsDoesNotOverflow() throws {
        let largestDenominator = try #require(Ratio.Denominator(exactly: Int64.max))

        #expect(roundsIdentically(GBP.max.unrounded * Ratio(3, largestDenominator)) == GBP(minorUnits: 3))
    }

    @Test("Scaling past the largest amount traps")
    func scalingPastTheLargestAmountTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max.unrounded * Ratio(3, 1))
        }
    }

    @Test("Scaling past the smallest amount traps")
    func scalingPastTheSmallestAmountTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min.unrounded * Ratio(3, 1))
        }
    }

    // Settling cannot overflow, whatever the amount: a denominator of one leaves nothing to settle, and
    // any larger denominator has already at least halved the amount, so the step to the next unit
    // always fits.
    @Test("Settling the largest and smallest amounts never overflows", arguments: everyRule)
    func settlingTheExtremesNeverOverflows(rule: RoundingRule) {
        #expect(GBP.max.unrounded.rounded(rule) == GBP.max)
        #expect(GBP.min.unrounded.rounded(rule) == GBP.min)
    }

    // A third of either extreme leaves part of a unit over, so the rules that move away from zero take
    // the step that would overflow if settling were not total.
    @Test("Settling a fraction of an extreme amount steps without overflowing")
    func settlingAFractionOfAnExtremeSteps() {
        let largest = GBP.max.unrounded * Ratio(1, 3)
        let smallest = GBP.min.unrounded * Ratio(1, 3)

        #expect(largest.rounded(.towardZero) == GBP(minorUnits: Int64.max / 3))
        #expect(largest.rounded(.awayFromZero) == GBP(minorUnits: Int64.max / 3 + 1))
        #expect(smallest.rounded(.towardZero) == GBP(minorUnits: Int64.min / 3))
        #expect(smallest.rounded(.awayFromZero) == GBP(minorUnits: Int64.min / 3 - 1))
    }

    // MARK: - Addition and subtraction

    @Test("Amounts over the same denominator add")
    func sameDenominatorAdds() {
        let third = GBP(minorUnits: 10_00).unrounded * Ratio(1, 3)

        #expect(roundsIdentically(third + third + third) == GBP(minorUnits: 10_00))
    }

    @Test("Amounts over different denominators add")
    func differentDenominatorsAdd() {
        let aThird = GBP(minorUnits: 3_00).unrounded * Ratio(1, 3)
        let aQuarter = GBP(minorUnits: 4_00).unrounded * Ratio(1, 4)

        #expect(roundsIdentically(aThird + aQuarter) == GBP(minorUnits: 2_00))
    }

    @Test("Amounts subtract")
    func amountsSubtract() {
        let aThird = GBP(minorUnits: 10_00).unrounded * Ratio(1, 3)
        let twoThirds = GBP(minorUnits: 20_00).unrounded * Ratio(1, 3)

        #expect(roundsIdentically(twoThirds - aThird) == nil)
        #expect(roundsIdentically(twoThirds - aThird - aThird) == GBP(minorUnits: 0))
    }

    // Over the product of the denominators this would need 10^36. Over their lowest common multiple it
    // needs 10^18, which fits.
    @Test("Amounts over the same large denominator add without overflowing")
    func sameLargeDenominatorAdds() {
        let tiny = GBP(minorUnits: 1).unrounded * Ratio(1, 1_000_000_000_000_000_000)

        #expect((tiny + tiny).rounded(.towardZero) == GBP.zero)
        #expect((tiny + tiny).rounded(.awayFromZero) == GBP(minorUnits: 1))
    }

    @Test("Adding and subtracting in place match the operators")
    func inPlaceMatches() {
        let third = GBP(minorUnits: 10_00).unrounded * Ratio(1, 3)

        var added = third
        added += third

        var subtracted = third
        subtracted -= third

        #expect(added == third + third)
        #expect(subtracted == GBP.Unrounded.zero)
    }

    // MARK: - Mixing with settled money

    @Test("A settled amount can join a chain from either side")
    func settledMoneyJoinsAChain() {
        let third = GBP(minorUnits: 9_99).unrounded * Ratio(1, 3)

        #expect(roundsIdentically(third + GBP(minorUnits: 1_00)) == GBP(minorUnits: 4_33))
        #expect(roundsIdentically(GBP(minorUnits: 1_00) + third) == GBP(minorUnits: 4_33))
        #expect(roundsIdentically(third - GBP(minorUnits: 1_00)) == GBP(minorUnits: 2_33))
        #expect(roundsIdentically(GBP(minorUnits: 1_00) - third) == GBP(minorUnits: -2_33))
    }

    @Test("A settled amount can join a chain in place")
    func settledMoneyJoinsInPlace() {
        var running = GBP(minorUnits: 9_99).unrounded * Ratio(1, 3)
        running += GBP(minorUnits: 1_00)
        running -= GBP(minorUnits: 2_00)

        #expect(roundsIdentically(running) == GBP(minorUnits: 2_33))
    }

    // The whole library in one expression, and the one place `split` belongs.
    @Test("A discounted, taxed line apportions across cost centres")
    func aDiscountedTaxedLineApportions() {
        let net = GBP(minorUnits: 5_00).unrounded * Ratio(1, 3) + GBP(minorUnits: 2_00) - GBP(minorUnits: 1_00)
        let shares = net.rounded(.toNearestOrEven).split(into: 2)

        #expect(Array(shares.amounts) == [GBP(minorUnits: 1_34), GBP(minorUnits: 1_33)])
    }

    // MARK: - Zero

    // Written out rather than as `.zero`: with a settled amount addable to an unrounded one, a leading
    // dot cannot tell which type's zero is meant. That is a compile error rather than a wrong answer,
    // and it is the price of letting the two mix.
    @Test("Zero leaves an amount unchanged")
    func zeroLeavesAnAmountUnchanged() {
        let third = GBP(minorUnits: 10_00).unrounded * Ratio(1, 3)

        #expect(third + GBP.Unrounded.zero == third)
        #expect(GBP.Unrounded.zero + third == third)
        #expect(third + GBP.zero == third)
        #expect(GBP.Unrounded.zero.rounded(.awayFromZero) == GBP.zero)
    }

    // 365 additions, all over the same denominator, and the year comes out exactly. The case the type
    // exists for: settling each day would drift.
    @Test("A year of daily accrual sums to the annual rate exactly")
    func aYearOfDailyAccrualIsExact() {
        let balance = GBP(minorUnits: 10_000_00)
        let daily = Ratio(45, 365_000)
        var accrued = GBP.Unrounded.zero

        for _ in 0 ..< 365 {
            accrued += balance.unrounded * daily
        }

        #expect(roundsIdentically(accrued) == GBP(minorUnits: 450_00))
    }

    @Test("Adding past the largest amount traps")
    func addingPastTheLargestAmountTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max.unrounded + GBP.max.unrounded)
        }
    }

    @Test("Subtracting past the smallest amount traps")
    func subtractingPastTheSmallestAmountTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min.unrounded - GBP.max.unrounded)
        }
    }

    // MARK: - Equatable and Hashable

    @Test("Equal chains are equal however they were reached")
    func equalChainsAreEqual() {
        #expect(GBP(minorUnits: 10_00).unrounded * Ratio(2, 6) == GBP(minorUnits: 10_00).unrounded * Ratio(1, 3))
    }

    @Test("Equal chains hash alike")
    func equalChainsHashAlike() {
        let chains = Set([GBP(minorUnits: 10_00).unrounded * Ratio(2, 6), GBP(minorUnits: 10_00).unrounded * Ratio(1, 3)])

        #expect(chains.count == 1)
    }
}

private let everyRule: [RoundingRule] = [
    .towardZero,
    .awayFromZero,
    .down,
    .up,
    .toNearestOrEven,
    .toNearestOrAwayFromZero,
]

// An exact amount settles to the same whole number whichever rule is applied, and an inexact one does
// not. Asking every rule is a stronger check on exactness than reading a remainder would be, and it is
// the only one available: an unrounded amount reports no remainder.
private func roundsIdentically<C: CurrencyType>(
    _ unrounded: MoneyOf<C>.Unrounded
) -> MoneyOf<C>? {
    let settled = Set(everyRule.map(unrounded.rounded))

    return settled.count == 1 ? settled.first : nil
}
