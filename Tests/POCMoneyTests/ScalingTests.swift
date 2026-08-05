import POCMoney
import Testing

@Suite("Scaling Tests")
struct ScalingTests {

    // MARK: - Exact

    @Test("A fraction that divides exactly reports no remainder")
    func exactDivision() {
        #expect(GBP(9_99).scaled(by: Ratio(1, 3)) == .exact(GBP(3_33)))
    }

    @Test("A whole ratio multiplies")
    func wholeRatio() {
        #expect(GBP(1_00).scaled(by: Ratio(3, 1)) == .exact(GBP(3_00)))
    }

    @Test("Scaling by zero is zero")
    func zeroRatio() {
        #expect(GBP(10_00).scaled(by: Ratio(0, 1)) == .exact(GBP.zero))
    }

    @Test("Scaling zero is zero")
    func zeroAmount() {
        #expect(GBP.zero.scaled(by: Ratio(1, 3)) == .exact(GBP.zero))
    }

    // MARK: - Inexact

    @Test("A fraction that does not divide exactly reports the part left over")
    func inexactDivision() {
        #expect(GBP(10_00).scaled(by: Ratio(1, 3)) == .inexact(GBP(3_33), remainder: Ratio(1, 3)))
    }

    @Test("The remainder is reduced to lowest terms")
    func remainderIsReduced() {
        // A quarter of 10 is 2 with 2/4 left over, reported as 1/2.
        #expect(GBP(10).scaled(by: Ratio(1, 4)) == .inexact(GBP(2), remainder: Ratio(1, 2)))
    }

    // MARK: - Sign

    // The amount truncates toward zero and the remainder takes the same sign, so the two together
    // account for the exact product: -333 and -1/3, never -334 and 2/3.
    @Test("A negative amount truncates toward zero")
    func negativeAmount() {
        #expect(GBP(-10_00).scaled(by: Ratio(1, 3)) == .inexact(GBP(-3_33), remainder: Ratio(-1, 3)))
    }

    @Test("A negative ratio negates the result")
    func negativeRatio() {
        #expect(GBP(10_00).scaled(by: Ratio(-1, 3)) == .inexact(GBP(-3_33), remainder: Ratio(-1, 3)))
    }

    @Test("Two negatives make a positive")
    func negativeAmountAndRatio() {
        #expect(GBP(-10_00).scaled(by: Ratio(-1, 3)) == .inexact(GBP(3_33), remainder: Ratio(1, 3)))
    }

    // MARK: - Extremes

    // Doubling the largest amount does not fit, but two thirds of it does. Scaling multiplies at double
    // width, so this is exact rather than a reported overflow.
    //
    // The largest amount leaves 1 over when divided by three, so two thirds of it is `Int.max / 3 * 2`
    // with 2/3 to spare.
    @Test("An amount whose doubled product would not fit still scales")
    func amountWhoseProductWouldNotFit() {
        #expect(
            GBP.max.scaled(by: Ratio(2, 3)) == .inexact(GBP(Int.max / 3 * 2), remainder: Ratio(2, 3))
        )
    }

    // The smallest amount has no positive counterpart, so rebuilding it from a magnitude is the one
    // case that could overflow on the way back.
    @Test("The smallest amount scales")
    func smallestAmountScales() {
        #expect(GBP.min.scaled(by: Ratio(1, 1)) == .exact(GBP.min))
        #expect(GBP.min.scaled(by: Ratio(1, 2)) == .exact(GBP(Int.min / 2)))
    }

    // MARK: - Overflow

    @Test("Scaling past the largest amount traps")
    func scalingPastTheLargestAmountTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max.scaled(by: Ratio(2, 1)))
        }
    }

    @Test("Scaling past the smallest amount traps")
    func scalingPastTheSmallestAmountTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min.scaled(by: Ratio(2, 1)))
        }
    }
}
