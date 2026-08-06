import POCMoney
import Testing

@Suite("Unrounded Tests")
struct UnroundedTests {

    // MARK: - The reason the type exists

    @Test("A chain settles once, where scaling settles at every step")
    func aChainSettlesOnce() {
        let chained = GBP(10_00).unrounded * Ratio(1, 3) * Ratio(3, 1)
        let scaledTwice = GBP(10_00)
            .scaled(by: Ratio(1, 3), rounding: .toNearestOrEven)
            .scaled(by: Ratio(3, 1), rounding: .toNearestOrEven)

        #expect(chained.rounded(.toNearestOrEven) == GBP(10_00))
        #expect(scaledTwice == GBP(9_99))
    }

    // The example the type's own documentation gives: 4.5% a year accrued over 31 days on £10,000.
    @Test("Two rates chain into one settlement")
    func twoRatesChain() {
        let interest = GBP(10_000_00).unrounded * Ratio(45, 1000) * Ratio(31, 365)

        #expect(interest.rounded(.toNearestOrEven) == GBP(38_22))
    }

    // MARK: - Entry

    @Test("An amount survives a round trip", arguments: everyMode)
    func roundTrip(mode: RoundingMode) {
        #expect(GBP(12_34).unrounded.rounded(mode) == GBP(12_34))
        #expect(GBP(-12_34).unrounded.rounded(mode) == GBP(-12_34))
        #expect(GBP.zero.unrounded.rounded(mode) == GBP.zero)
    }

    // MARK: - Multiplication

    @Test("A ratio scales an amount")
    func ratioScales() {
        #expect(roundsIdentically(GBP(9_99).unrounded * Ratio(1, 3)) == GBP(3_33))
    }

    @Test("A ratio scales an amount from either side")
    func ratioScalesFromEitherSide() {
        let ratio = Ratio(1, 3)

        #expect(GBP(9_99).unrounded * ratio == ratio * GBP(9_99).unrounded)
    }

    // `Ratio` is deliberately not `ExpressibleByIntegerLiteral`, which is what keeps this unambiguous.
    @Test("A whole number scales an amount from either side")
    func wholeNumberScales() {
        #expect(roundsIdentically(GBP(1_00).unrounded * 3) == GBP(3_00))
        #expect(roundsIdentically(3 * GBP(1_00).unrounded) == GBP(3_00))
    }

    @Test("Scaling in place matches scaling")
    func scalingInPlace() {
        var byRatio = GBP(9_99).unrounded
        byRatio *= Ratio(1, 3)

        var byWholeNumber = GBP(1_00).unrounded
        byWholeNumber *= 3

        #expect(byRatio == GBP(9_99).unrounded * Ratio(1, 3))
        #expect(byWholeNumber == GBP(1_00).unrounded * 3)
    }

    @Test("Scaling by zero is zero", arguments: everyMode)
    func scalingByZero(mode: RoundingMode) {
        #expect((GBP(10_00).unrounded * Ratio(0, 1)).rounded(mode) == GBP.zero)
    }

    @Test("A chain keeps a fraction no single step could")
    func aChainKeepsAFraction() {
        let third = GBP(10_00).unrounded * Ratio(1, 3)

        #expect(third.rounded(.towardZero) == GBP(3_33))
        #expect(third.rounded(.awayFromZero) == GBP(3_34))
    }

    // MARK: - Exactness

    @Test("An exact chain rounds the same way under every mode")
    func anExactChainIsIndifferentToMode() {
        #expect(roundsIdentically(GBP(30_00).unrounded * Ratio(18, 30) * Ratio(11, 18)) == GBP(11_00))
    }

    @Test("An inexact chain does not round the same way under every mode")
    func anInexactChainIsNotIndifferentToMode() {
        #expect(roundsIdentically(GBP(10_00).unrounded * Ratio(1, 3)) == nil)
    }

    // MARK: - Overflow

    // Naively this multiplies the largest amount by three, which does not fit. Cancelling it against
    // the denominator first leaves three over one.
    @Test("A product that cancels does not overflow")
    func aProductThatCancelsDoesNotOverflow() throws {
        let largestDenominator = try #require(Ratio.Denominator(exactly: Int64.max))

        #expect(roundsIdentically(GBP.max.unrounded * Ratio(3, largestDenominator)) == GBP(3))
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
    @Test("Settling the largest and smallest amounts never overflows", arguments: everyMode)
    func settlingTheExtremesNeverOverflows(mode: RoundingMode) {
        #expect(GBP.max.unrounded.rounded(mode) == GBP.max)
        #expect(GBP.min.unrounded.rounded(mode) == GBP.min)
    }

    // A third of either extreme leaves part of a unit over, so the modes that move away from zero take
    // the step that would overflow if settling were not total.
    @Test("Settling a fraction of an extreme amount steps without overflowing")
    func settlingAFractionOfAnExtremeSteps() {
        let largest = GBP.max.unrounded * Ratio(1, 3)
        let smallest = GBP.min.unrounded * Ratio(1, 3)

        #expect(largest.rounded(.towardZero) == GBP(Int64.max / 3))
        #expect(largest.rounded(.awayFromZero) == GBP(Int64.max / 3 + 1))
        #expect(smallest.rounded(.towardZero) == GBP(Int64.min / 3))
        #expect(smallest.rounded(.awayFromZero) == GBP(Int64.min / 3 - 1))
    }

    // MARK: - Equatable and Hashable

    @Test("Equal chains are equal however they were reached")
    func equalChainsAreEqual() {
        #expect(GBP(10_00).unrounded * Ratio(2, 6) == GBP(10_00).unrounded * Ratio(1, 3))
    }

    @Test("Equal chains hash alike")
    func equalChainsHashAlike() {
        let chains = Set([GBP(10_00).unrounded * Ratio(2, 6), GBP(10_00).unrounded * Ratio(1, 3)])

        #expect(chains.count == 1)
    }
}

private let everyMode: [RoundingMode] = [
    .towardZero,
    .awayFromZero,
    .floor,
    .ceiling,
    .toNearestOrEven,
    .toNearestOrAwayFromZero,
]

// An exact amount settles to the same whole number whichever mode is applied, and an inexact one does
// not. Asking every mode is a stronger check on exactness than reading a remainder would be, and it is
// the only one available: an unrounded amount reports no remainder.
private func roundsIdentically<C: CurrencyType>(
    _ unrounded: MoneyOf<C>.Unrounded
) -> MoneyOf<C>? {
    let settled = Set(everyMode.map(unrounded.rounded))

    return settled.count == 1 ? settled.first : nil
}
