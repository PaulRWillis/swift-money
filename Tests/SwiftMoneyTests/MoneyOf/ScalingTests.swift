import SwiftMoney
import Testing

@Suite("Scaling Tests")
struct ScalingTests {

    @Test("A fraction that divides exactly reports no remainder")
    func exactDivision() {
        #expect(GBP(minorUnits: 9_99).scaled(by: "1/3") == .exact(GBP(minorUnits: 3_33)))
    }

    @Test("A whole ratio multiplies")
    func wholeRatio() {
        #expect(GBP(minorUnits: 1_00).scaled(by: "3/1") == .exact(GBP(minorUnits: 3_00)))
    }

    @Test("Scaling by zero is zero")
    func zeroRatio() {
        #expect(GBP(minorUnits: 10_00).scaled(by: "0/1") == .exact(GBP.zero))
    }

    @Test("Scaling zero is zero")
    func zeroAmount() {
        #expect(GBP.zero.scaled(by: "1/3") == .exact(GBP.zero))
    }

    @Test("A fraction that does not divide exactly reports the part left over")
    func inexactDivision() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(minorUnits: 10_00).scaled(by: "1/3")))

        #expect(amount == GBP(minorUnits: 3_33))
        #expect(remainder == "1/3")
    }

    // The remainder is a fraction of the ratio's own denominator, not of anything else: a quarter of 10
    // is 2 with 2 of 4 left over, which as a ratio is a half.
    @Test("The remainder is the part of one unit left over")
    func remainderIsThePartOfOneUnitLeftOver() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(minorUnits: 10).scaled(by: "1/4")))

        #expect(amount == GBP(minorUnits: 2))
        #expect(remainder == "1/2")
    }

    @Test("A remainder describes itself as its fraction")
    func remainderDescription() throws {
        let scaled = GBP(minorUnits: 10_00).scaled(by: "1/3")

        #expect(String(describing: scaled).contains("1/3"))
    }

    // The amount truncates toward zero and the remainder takes the same sign, so the two together
    // account for the exact product: -333 and -1/3, never -334 and 2/3.
    @Test("A negative amount truncates toward zero")
    func negativeAmount() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(minorUnits: -10_00).scaled(by: "1/3")))

        #expect(amount == GBP(minorUnits: -3_33))
        #expect(remainder == "-1/3")
    }

    @Test("A negative ratio negates the result")
    func negativeRatio() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(minorUnits: 10_00).scaled(by: "-1/3")))

        #expect(amount == GBP(minorUnits: -3_33))
        #expect(remainder == "-1/3")
    }

    @Test("Two negatives make a positive")
    func negativeAmountAndRatio() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(minorUnits: -10_00).scaled(by: "-1/3")))

        #expect(amount == GBP(minorUnits: 3_33))
        #expect(remainder == "1/3")
    }

    // Doubling the largest amount does not fit, but two thirds of it does. Scaling multiplies at double
    // width, so this is exact rather than a reported overflow.
    //
    // The largest amount leaves 1 over when divided by three, so two thirds of it is `Int64.max / 3 * 2`
    // with 2/3 to spare.
    @Test("An amount whose doubled product would not fit still scales")
    func amountWhoseProductWouldNotFit() throws {
        let (amount, remainder) = try #require(inexactParts(GBP.max.scaled(by: "2/3")))

        #expect(amount == GBP(minorUnits: Int64.max / 3 * 2))
        #expect(remainder == "2/3")
    }

    // The smallest amount has no positive counterpart, so rebuilding it from a magnitude is the one
    // case that could overflow on the way back.
    @Test("The smallest amount scales")
    func smallestAmountScales() {
        #expect(GBP.min.scaled(by: "1/1") == .exact(GBP.min))
        #expect(GBP.min.scaled(by: "1/2") == .exact(GBP(minorUnits: Int64.min / 2)))
    }

    // A quarter of 10 is 2.5: exactly between two whole units, which is where the rules differ most.
    @Test(
        "Every rule resolves an exact half",
        arguments: [
            (RoundingRule.towardZero, GBP(minorUnits: 2)),
            (.awayFromZero, GBP(minorUnits: 3)),
            (.down, GBP(minorUnits: 2)),
            (.up, GBP(minorUnits: 3)),
            (.toNearestOrEven, GBP(minorUnits: 2)),
            (.toNearestOrAwayFromZero, GBP(minorUnits: 3)),
        ]
    )
    func rulesAtAnExactHalf(rule: RoundingRule, expected: GBP) {
        #expect(GBP(minorUnits: 10).scaled(by: "1/4", rounding: rule) == expected)
    }

    // A quarter of 9 is 2.25, so the nearest whole unit is the one it was truncated to.
    @Test(
        "Every rule resolves a fraction below a half",
        arguments: [
            (RoundingRule.towardZero, GBP(minorUnits: 2)),
            (.awayFromZero, GBP(minorUnits: 3)),
            (.down, GBP(minorUnits: 2)),
            (.up, GBP(minorUnits: 3)),
            (.toNearestOrEven, GBP(minorUnits: 2)),
            (.toNearestOrAwayFromZero, GBP(minorUnits: 2)),
        ]
    )
    func rulesBelowAHalf(rule: RoundingRule, expected: GBP) {
        #expect(GBP(minorUnits: 9).scaled(by: "1/4", rounding: rule) == expected)
    }

    // A quarter of 11 is 2.75, so both nearest rules step where they did not at 2.25.
    @Test(
        "Every rule resolves a fraction above a half",
        arguments: [
            (RoundingRule.towardZero, GBP(minorUnits: 2)),
            (.awayFromZero, GBP(minorUnits: 3)),
            (.down, GBP(minorUnits: 2)),
            (.up, GBP(minorUnits: 3)),
            (.toNearestOrEven, GBP(minorUnits: 3)),
            (.toNearestOrAwayFromZero, GBP(minorUnits: 3)),
        ]
    )
    func rulesAboveAHalf(rule: RoundingRule, expected: GBP) {
        #expect(GBP(minorUnits: 11).scaled(by: "1/4", rounding: rule) == expected)
    }

    // A quarter of -10 is -2.5. This is where `.down` and `.towardZero` part company, and where
    // `.awayFromZero` and `.up` do: a sign error in a rule shows up here and nowhere else.
    @Test(
        "Every rule resolves a negative exact half",
        arguments: [
            (RoundingRule.towardZero, GBP(minorUnits: -2)),
            (.awayFromZero, GBP(minorUnits: -3)),
            (.down, GBP(minorUnits: -3)),
            (.up, GBP(minorUnits: -2)),
            (.toNearestOrEven, GBP(minorUnits: -2)),
            (.toNearestOrAwayFromZero, GBP(minorUnits: -3)),
        ]
    )
    func rulesAtANegativeExactHalf(rule: RoundingRule, expected: GBP) {
        #expect(GBP(minorUnits: -10).scaled(by: "1/4", rounding: rule) == expected)
    }

    // Banker's rounding breaks a tie toward the even neighbour, so 2.5 and 3.5 both settle on an even
    // number rather than both going the same direction.
    @Test("An exact half rounds to even in both directions")
    func exactHalfRoundsToEven() {
        #expect(GBP(minorUnits: 10).scaled(by: "1/4", rounding: .toNearestOrEven) == GBP(minorUnits: 2))
        #expect(GBP(minorUnits: 14).scaled(by: "1/4", rounding: .toNearestOrEven) == GBP(minorUnits: 4))
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
        #expect(GBP(minorUnits: 8).scaled(by: "1/4", rounding: rule) == GBP(minorUnits: 2))
    }

    @Test("Truncating reaches the largest amount exactly")
    func truncatingReachesTheLargestAmount() {
        #expect(threeHalvesOfThisIsTheLargestAmount.scaled(by: threeHalves, rounding: .towardZero) == GBP.max)
    }

    @Test("Rounding traps on overflow, where truncating would not")
    func roundingTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(threeHalvesOfThisIsTheLargestAmount.scaled(by: threeHalves, rounding: .awayFromZero))
        }
    }

    @Test("Scaling traps on overflow")
    func scalingTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max.scaled(by: "2/1"))
        }
    }

    @Test("Scaling traps on underflow")
    func scalingTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min.scaled(by: "2/1"))
        }
    }
}

private let threeHalves: Ratio = "3/2"

// Three halves of this amount is exactly the largest amount, with a half left over, so truncating fits
// and only the rounding step passes the maximum. At file scope because an exit test runs in a child
// process, so its closure cannot capture a local.
private let threeHalvesOfThisIsTheLargestAmount = GBP(minorUnits: Int64.max / 3 * 2 + 1)

// An inexact result cannot be built from outside the module (that is what stops one claiming a
// remainder it does not have), so these tests read the parts back out rather than comparing against a
// constructed value.
private func inexactParts<Amount>(
    _ scaled: Scaled<Amount>
) -> (amount: Amount, remainder: Ratio)? {
    guard case let .inexact(amount, remainder) = scaled else {
        return nil
    }

    return (amount, Ratio(remainder))
}
