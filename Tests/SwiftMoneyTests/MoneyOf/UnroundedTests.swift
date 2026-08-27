import SwiftMoney
import Testing

@Suite("Unrounded Tests")
struct UnroundedTests {

    @Test("A chain settles once, where scaling settles at every step")
    func aChainSettlesOnce() throws {
        let third = try #require(Rate(string: "1/3"))
        let chained = GBP(minorUnits: 10_00).unrounded * third * "3"
        let scaledTwice = GBP(minorUnits: 10_00)
            .applying(third).rounded(.toNearestOrEven)
            .applying("3").rounded(.toNearestOrEven)

        #expect(chained.rounded(.toNearestOrEven) == GBP(minorUnits: 10_00))
        #expect(scaledTwice == GBP(minorUnits: 9_99))
    }

    // The example the type's own documentation gives: 4.5% a year accrued over 31 days on £10,000.
    @Test("Two rates chain into one settlement")
    func twoRatesChain() throws {
        let dayCount = try #require(Rate(string: "31/365"))
        let interest = GBP(minorUnits: 10_000_00).unrounded * "45/1000" * dayCount

        #expect(interest.rounded(.toNearestOrEven) == GBP(minorUnits: 38_22))
    }

    @Test("An amount survives a round trip", arguments: everyRule)
    func roundTrip(rule: RoundingRule) {
        #expect(GBP(minorUnits: 12_34).unrounded.rounded(rule) == GBP(minorUnits: 12_34))
        #expect(GBP(minorUnits: -12_34).unrounded.rounded(rule) == GBP(minorUnits: -12_34))
        #expect(GBP.zero.unrounded.rounded(rule) == GBP.zero)
    }

    @Test("A rate scales an amount to within a minor unit")
    func rateScales() throws {
        let third = try #require(Rate(string: "1/3"))

        #expect((GBP(minorUnits: 9_99).unrounded * third).rounded(.toNearestOrEven) == GBP(minorUnits: 3_33))
    }

    @Test("A rate scales an amount from either side")
    func rateScalesFromEitherSide() throws {
        let third = try #require(Rate(string: "1/3"))

        #expect(GBP(minorUnits: 9_99).unrounded * third == third * GBP(minorUnits: 9_99).unrounded)
    }

    @Test("Applying a rate matches the multiply operator")
    func applyingMatchesMultiply() throws {
        let third = try #require(Rate(string: "1/3"))
        let amount = GBP(minorUnits: 9_99).unrounded

        #expect(amount.applying(third) == amount * third)
    }

    @Test("Dividing keeps a fraction for one settling")
    func dividedByWholeNumber() {
        #expect(GBP(minorUnits: 10_00).unrounded.divided(by: 3).rounded(.toNearestOrEven) == GBP(minorUnits: 3_33))
        #expect(GBP(minorUnits: 10_00).unrounded.divided(by: 4).rounded(.toNearestOrEven) == GBP(minorUnits: 2_50))
    }

    @Test("Dividing by exactly zero is nil, not a trap")
    func dividedByExactlyZero() throws {
        #expect(GBP(minorUnits: 10_00).unrounded.divided(byExactly: 0) == nil)

        let quarter = try #require(GBP(minorUnits: 10_00).unrounded.divided(byExactly: 4))
        #expect(quarter.rounded(.toNearestOrEven) == GBP(minorUnits: 2_50))
    }

    @Test("Dividing by zero traps")
    func dividingByZeroTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: 10_00).unrounded.divided(by: 0))
        }
    }

    // The case the type exists for: five years of daily interest, rounded once, matches the annual
    // figure to within a minor unit, where settling each day drifts away from it.
    @Test("Daily accrual over five years rounds once to within a minor unit")
    func dailyAccrualRoundsOnce() throws {
        let balance = GBP(minorUnits: 10_000_00)              // £10,000
        let annualRate = try #require(Rate(string: "0.05"))   // 5%
        let days = 1_826                                      // five years, including a leap day

        let daily = (balance.unrounded * annualRate).divided(by: 365)
        var accrued = GBP.Unrounded.zero
        for _ in 0 ..< days {
            accrued += daily
        }
        let roundedOnce = accrued.rounded(.toNearestOrEven)

        let singleShot = ((balance.unrounded * annualRate) * days).divided(by: 365).rounded(.toNearestOrEven)
        let withinOne = Set([singleShot, singleShot + GBP(minorUnits: 1), singleShot - GBP(minorUnits: 1)])
        #expect(withinOne.contains(roundedOnce))

        var settledDaily = GBP.zero
        for _ in 0 ..< days {
            settledDaily = settledDaily + daily.rounded(.toNearestOrEven)
        }
        #expect(settledDaily != roundedOnce)
    }

    @Test("A fractional amount can be built from minor units")
    func fromMinorUnits() {
        let price = GBP.Unrounded(minorUnits: "2.3")

        #expect(price.rounded(.toNearestOrEven) == GBP(minorUnits: 2))
        #expect((price * 10).rounded(.toNearestOrEven) == GBP(minorUnits: 23))
    }

    @Test("A fractional amount can be built from major units")
    func fromMajorUnits() {
        let price = GBP.Unrounded(majorUnits: "0.023")   // £0.023 = 2.3 pence

        #expect((price * 1_000).rounded(.toNearestOrEven) == GBP(minorUnits: 23_00))
    }

    // `Rate` is deliberately not `ExpressibleByIntegerLiteral`, which is what keeps this unambiguous.
    @Test("A whole number scales an amount from either side")
    func wholeNumberScales() {
        #expect(roundsIdentically(GBP(minorUnits: 1_00).unrounded * 3) == GBP(minorUnits: 3_00))
        #expect(roundsIdentically(3 * GBP(minorUnits: 1_00).unrounded) == GBP(minorUnits: 3_00))
    }

    @Test("Scaling in place matches scaling")
    func scalingInPlace() throws {
        let third = try #require(Rate(string: "1/3"))

        var byRate = GBP(minorUnits: 9_99).unrounded
        byRate *= third

        var byWholeNumber = GBP(minorUnits: 1_00).unrounded
        byWholeNumber *= 3

        #expect(byRate == GBP(minorUnits: 9_99).unrounded * third)
        #expect(byWholeNumber == GBP(minorUnits: 1_00).unrounded * 3)
    }

    @Test("Scaling by zero is zero", arguments: everyRule)
    func scalingByZero(rule: RoundingRule) {
        #expect((GBP(minorUnits: 10_00).unrounded * "0/1").rounded(rule) == GBP.zero)
    }

    @Test("A chain keeps a fraction no single step could")
    func aChainKeepsAFraction() throws {
        let third = try GBP(minorUnits: 10_00).unrounded * #require(Rate(string: "1/3"))

        #expect(third.rounded(.towardZero) == GBP(minorUnits: 3_33))
        #expect(third.rounded(.awayFromZero) == GBP(minorUnits: 3_34))
    }

    @Test("An exact chain rounds the same way under every rule")
    func anExactChainIsIndifferentToRule() {
        #expect(roundsIdentically(GBP(minorUnits: 30_00).unrounded * "0.5" * "0.4") == GBP(minorUnits: 6_00))
    }

    @Test("An inexact chain does not round the same way under every rule")
    func anInexactChainIsNotIndifferentToRule() throws {
        let third = try #require(Rate(string: "1/3"))

        #expect(roundsIdentically(GBP(minorUnits: 10_00).unrounded * third) == nil)
    }

    @Test("Scaling traps on overflow")
    func scalingTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max.unrounded * 20)
        }
    }

    @Test("Scaling traps on underflow")
    func scalingTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min.unrounded * 20)
        }
    }

    @Test("Settling the largest and smallest amounts never overflows", arguments: everyRule)
    func settlingTheExtremesNeverOverflows(rule: RoundingRule) {
        #expect(GBP.max.unrounded.rounded(rule) == GBP.max)
        #expect(GBP.min.unrounded.rounded(rule) == GBP.min)
    }

    // A third of either extreme leaves part of a unit over, so rounding away from zero steps one minor
    // unit past rounding toward it, and neither step overflows.
    @Test("Settling a fraction of an extreme amount steps by one without overflowing")
    func settlingAFractionOfAnExtremeSteps() throws {
        let third = try #require(Rate(string: "1/3"))
        let largest = GBP.max.unrounded * third
        let smallest = GBP.min.unrounded * third

        #expect(largest.rounded(.awayFromZero) == largest.rounded(.towardZero) + GBP(minorUnits: 1))
        #expect(smallest.rounded(.awayFromZero) == smallest.rounded(.towardZero) - GBP(minorUnits: 1))
    }

    @Test("Amounts add and settle once")
    func amountsAddAndSettleOnce() throws {
        let third = try GBP(minorUnits: 10_00).unrounded * #require(Rate(string: "1/3"))

        #expect((third + third + third).rounded(.toNearestOrEven) == GBP(minorUnits: 10_00))
    }

    @Test("Amounts from different rates add and settle once")
    func differentRatesAdd() throws {
        let aThird = try GBP(minorUnits: 3_00).unrounded * #require(Rate(string: "1/3"))
        let aQuarter = GBP(minorUnits: 4_00).unrounded * "1/4"

        #expect((aThird + aQuarter).rounded(.toNearestOrEven) == GBP(minorUnits: 2_00))
    }

    @Test("Amounts subtract")
    func amountsSubtract() throws {
        let third = try #require(Rate(string: "1/3"))
        let aThird = GBP(minorUnits: 10_00).unrounded * third
        let twoThirds = GBP(minorUnits: 20_00).unrounded * third

        #expect(roundsIdentically(twoThirds - aThird) == nil)
        #expect(twoThirds - aThird - aThird == GBP.Unrounded.zero)
    }

    // A minor unit split a quintillion ways is exactly representable, so two of them settle predictably.
    @Test("Sub-unit amounts add without overflowing")
    func subUnitAmountsAdd() {
        let tiny = GBP(minorUnits: 1).unrounded * "0.000000000000000001"

        #expect((tiny + tiny).rounded(.towardZero) == GBP.zero)
        #expect((tiny + tiny).rounded(.awayFromZero) == GBP(minorUnits: 1))
    }

    @Test("Adding and subtracting in place match the operators")
    func inPlaceMatches() throws {
        let third = try GBP(minorUnits: 10_00).unrounded * #require(Rate(string: "1/3"))

        var added = third
        added += third

        var subtracted = third
        subtracted -= third

        #expect(added == third + third)
        #expect(subtracted == GBP.Unrounded.zero)
    }

    @Test("A settled amount can join a chain from either side")
    func settledMoneyJoinsAChain() throws {
        let third = try GBP(minorUnits: 9_99).unrounded * #require(Rate(string: "1/3"))

        #expect((third + GBP(minorUnits: 1_00)).rounded(.toNearestOrEven) == GBP(minorUnits: 4_33))
        #expect((GBP(minorUnits: 1_00) + third).rounded(.toNearestOrEven) == GBP(minorUnits: 4_33))
        #expect((third - GBP(minorUnits: 1_00)).rounded(.toNearestOrEven) == GBP(minorUnits: 2_33))
        #expect((GBP(minorUnits: 1_00) - third).rounded(.toNearestOrEven) == GBP(minorUnits: -2_33))
    }

    @Test("A settled amount can join a chain in place")
    func settledMoneyJoinsInPlace() throws {
        var running = try GBP(minorUnits: 9_99).unrounded * #require(Rate(string: "1/3"))
        running += GBP(minorUnits: 1_00)
        running -= GBP(minorUnits: 2_00)

        #expect(running.rounded(.toNearestOrEven) == GBP(minorUnits: 2_33))
    }

    // The whole library in one expression, and the one place `split` belongs.
    @Test("A discounted, taxed line apportions across cost centers")
    func aDiscountedTaxedLineApportions() throws {
        let third = try #require(Rate(string: "1/3"))
        let net = GBP(minorUnits: 5_00).unrounded * third + GBP(minorUnits: 2_00) - GBP(minorUnits: 1_00)
        let shares = net.rounded(.toNearestOrEven).split(into: 2)

        #expect(Array(shares.amounts) == [GBP(minorUnits: 1_34), GBP(minorUnits: 1_33)])
    }

    // Written out rather than as `.zero`: with a settled amount addable to an unrounded one, a leading
    // dot cannot tell which type's zero is meant. That is a compile error rather than a wrong answer,
    // and it is the price of letting the two mix.
    @Test("Zero leaves an amount unchanged")
    func zeroLeavesAnAmountUnchanged() throws {
        let third = try GBP(minorUnits: 10_00).unrounded * #require(Rate(string: "1/3"))

        #expect(third + GBP.Unrounded.zero == third)
        #expect(GBP.Unrounded.zero + third == third)
        #expect(third + GBP.zero == third)
        #expect(GBP.Unrounded.zero.rounded(.awayFromZero) == GBP.zero)
    }

    @Test("Adding traps on overflow")
    func addingTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            let huge = GBP.max.unrounded * 15
            blackHole(huge + huge)
        }
    }

    @Test("Subtracting traps on underflow")
    func subtractingTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            let huge = GBP.max.unrounded * 15
            blackHole(GBP.min.unrounded * 15 - huge)
        }
    }

    @Test("Equal chains are equal however they were reached")
    func equalChainsAreEqual() throws {
        let byHalves = try #require(Rate(string: "2/6"))
        let byThird = try #require(Rate(string: "1/3"))

        #expect(GBP(minorUnits: 10_00).unrounded * byHalves == GBP(minorUnits: 10_00).unrounded * byThird)
    }

    @Test("Equal chains hash alike")
    func equalChainsHashAlike() throws {
        let byHalves = try #require(Rate(string: "2/6"))
        let byThird = try #require(Rate(string: "1/3"))
        let chains = Set([GBP(minorUnits: 10_00).unrounded * byHalves, GBP(minorUnits: 10_00).unrounded * byThird])

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

// A whole number of minor units settles to the same amount whichever rule is applied, and a fractional
// one does not. Asking every rule is a stronger check on wholeness than reading a remainder would be, and
// it is the only one available: an unrounded amount reports no remainder.
private func roundsIdentically<C: CurrencyType>(
    _ unrounded: MoneyOf<C>.Unrounded
) -> MoneyOf<C>? {
    let settled = Set(everyRule.map(unrounded.rounded))

    return settled.count == 1 ? settled.first : nil
}
