import SwiftMoney
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
    func inexactDivision() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(10_00).scaled(by: Ratio(1, 3))))

        #expect(amount == GBP(3_33))
        #expect(remainder == Ratio(1, 3))
    }

    // The remainder is a fraction of the ratio's own denominator, not of anything else: a quarter of 10
    // is 2 with 2 of 4 left over, which as a ratio is a half.
    @Test("The remainder is the part of one unit left over")
    func remainderIsThePartOfOneUnitLeftOver() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(10).scaled(by: Ratio(1, 4))))

        #expect(amount == GBP(2))
        #expect(remainder == Ratio(1, 2))
    }

    @Test("A remainder describes itself as its fraction")
    func remainderDescription() throws {
        let scaled = GBP(10_00).scaled(by: Ratio(1, 3))

        #expect(String(describing: scaled).contains("1/3"))
    }

    // MARK: - Sign

    // The amount truncates toward zero and the remainder takes the same sign, so the two together
    // account for the exact product: -333 and -1/3, never -334 and 2/3.
    @Test("A negative amount truncates toward zero")
    func negativeAmount() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(-10_00).scaled(by: Ratio(1, 3))))

        #expect(amount == GBP(-3_33))
        #expect(remainder == Ratio(-1, 3))
    }

    @Test("A negative ratio negates the result")
    func negativeRatio() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(10_00).scaled(by: Ratio(-1, 3))))

        #expect(amount == GBP(-3_33))
        #expect(remainder == Ratio(-1, 3))
    }

    @Test("Two negatives make a positive")
    func negativeAmountAndRatio() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(-10_00).scaled(by: Ratio(-1, 3))))

        #expect(amount == GBP(3_33))
        #expect(remainder == Ratio(1, 3))
    }

    // MARK: - Extremes

    // Doubling the largest amount does not fit, but two thirds of it does. Scaling multiplies at double
    // width, so this is exact rather than a reported overflow.
    //
    // The largest amount leaves 1 over when divided by three, so two thirds of it is `Int64.max / 3 * 2`
    // with 2/3 to spare.
    @Test("An amount whose doubled product would not fit still scales")
    func amountWhoseProductWouldNotFit() throws {
        let (amount, remainder) = try #require(inexactParts(GBP.max.scaled(by: Ratio(2, 3))))

        #expect(amount == GBP(Int64.max / 3 * 2))
        #expect(remainder == Ratio(2, 3))
    }

    // The smallest amount has no positive counterpart, so rebuilding it from a magnitude is the one
    // case that could overflow on the way back.
    @Test("The smallest amount scales")
    func smallestAmountScales() {
        #expect(GBP.min.scaled(by: Ratio(1, 1)) == .exact(GBP.min))
        #expect(GBP.min.scaled(by: Ratio(1, 2)) == .exact(GBP(Int64.min / 2)))
    }

    // MARK: - Rounding

    // A quarter of 10 is 2.5 — exactly between two whole units, which is where the rules differ most.
    @Test(
        "Every rule resolves an exact half",
        arguments: [
            (RoundingRule.towardZero, GBP(2)),
            (.awayFromZero, GBP(3)),
            (.down, GBP(2)),
            (.up, GBP(3)),
            (.toNearestOrEven, GBP(2)),
            (.toNearestOrAwayFromZero, GBP(3)),
        ]
    )
    func rulesAtAnExactHalf(rule: RoundingRule, expected: GBP) {
        #expect(GBP(10).scaled(by: Ratio(1, 4), rounding: rule) == expected)
    }

    // A quarter of 9 is 2.25, so the nearest whole unit is the one it was truncated to.
    @Test(
        "Every rule resolves a fraction below a half",
        arguments: [
            (RoundingRule.towardZero, GBP(2)),
            (.awayFromZero, GBP(3)),
            (.down, GBP(2)),
            (.up, GBP(3)),
            (.toNearestOrEven, GBP(2)),
            (.toNearestOrAwayFromZero, GBP(2)),
        ]
    )
    func rulesBelowAHalf(rule: RoundingRule, expected: GBP) {
        #expect(GBP(9).scaled(by: Ratio(1, 4), rounding: rule) == expected)
    }

    // A quarter of 11 is 2.75, so both nearest rules step where they did not at 2.25.
    @Test(
        "Every rule resolves a fraction above a half",
        arguments: [
            (RoundingRule.towardZero, GBP(2)),
            (.awayFromZero, GBP(3)),
            (.down, GBP(2)),
            (.up, GBP(3)),
            (.toNearestOrEven, GBP(3)),
            (.toNearestOrAwayFromZero, GBP(3)),
        ]
    )
    func rulesAboveAHalf(rule: RoundingRule, expected: GBP) {
        #expect(GBP(11).scaled(by: Ratio(1, 4), rounding: rule) == expected)
    }

    // A quarter of -10 is -2.5. This is where `.down` and `.towardZero` part company, and where
    // `.awayFromZero` and `.up` do — a sign error in a rule shows up here and nowhere else.
    @Test(
        "Every rule resolves a negative exact half",
        arguments: [
            (RoundingRule.towardZero, GBP(-2)),
            (.awayFromZero, GBP(-3)),
            (.down, GBP(-3)),
            (.up, GBP(-2)),
            (.toNearestOrEven, GBP(-2)),
            (.toNearestOrAwayFromZero, GBP(-3)),
        ]
    )
    func rulesAtANegativeExactHalf(rule: RoundingRule, expected: GBP) {
        #expect(GBP(-10).scaled(by: Ratio(1, 4), rounding: rule) == expected)
    }

    // Banker's rounding breaks a tie toward the even neighbour, so 2.5 and 3.5 both settle on an even
    // number rather than both going the same direction.
    @Test("An exact half rounds to even in both directions")
    func exactHalfRoundsToEven() {
        #expect(GBP(10).scaled(by: Ratio(1, 4), rounding: .toNearestOrEven) == GBP(2))
        #expect(GBP(14).scaled(by: Ratio(1, 4), rounding: .toNearestOrEven) == GBP(4))
    }

    @Test(
        "A rule cannot change an exact result",
        arguments: [
            RoundingRule.towardZero,
            .awayFromZero,
            .down,
            .up,
            .toNearestOrEven,
            .toNearestOrAwayFromZero,
        ]
    )
    func exactResultsAreUnchanged(rule: RoundingRule) {
        #expect(GBP(8).scaled(by: Ratio(1, 4), rounding: rule) == GBP(2))
    }

    // MARK: - Overflow

    @Test("Truncating reaches the largest amount exactly")
    func truncatingReachesTheLargestAmount() {
        #expect(threeHalvesOfThisIsTheLargestAmount.scaled(by: threeHalves, rounding: .towardZero) == GBP.max)
    }

    @Test("Rounding past the largest amount traps, where truncating would not")
    func roundingPastTheLargestAmountTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(threeHalvesOfThisIsTheLargestAmount.scaled(by: threeHalves, rounding: .awayFromZero))
        }
    }

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

private let threeHalves = Ratio(3, 2)

// Three halves of this amount is exactly the largest amount, with a half left over — so truncating fits
// and only the rounding step passes the maximum. At file scope because an exit test runs in a child
// process, so its closure cannot capture a local.
private let threeHalvesOfThisIsTheLargestAmount = GBP(Int64.max / 3 * 2 + 1)

// An inexact result cannot be built from outside the module — that is what stops one claiming a
// remainder it does not have — so these tests read the parts back out rather than comparing against a
// constructed value.
private func inexactParts<Amount>(
    _ scaled: Scaled<Amount>
) -> (amount: Amount, remainder: Ratio)? {
    guard case let .inexact(amount, remainder) = scaled else {
        return nil
    }

    return (amount, Ratio(remainder))
}
