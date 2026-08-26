import SwiftMoney
import Testing

@Suite("Scaling Tests")
struct ScalingTests {

    @Test("A rate that divides exactly reports no remainder")
    func exactDivision() {
        #expect(GBP(minorUnits: 10_00).scaled(by: "0.2") == .exact(GBP(minorUnits: 2_00)))
    }

    @Test("A whole rate multiplies")
    func wholeRate() {
        #expect(GBP(minorUnits: 1_00).scaled(by: "3") == .exact(GBP(minorUnits: 3_00)))
    }

    @Test("Scaling by zero is zero")
    func zeroRate() {
        #expect(GBP(minorUnits: 10_00).scaled(by: "0") == .exact(GBP.zero))
    }

    @Test("Scaling zero is zero")
    func zeroAmount() throws {
        let third = try #require(Rate(string: "1/3"))

        #expect(GBP.zero.scaled(by: third) == .exact(GBP.zero))
    }

    // Ten scaled by a quarter is 2.5: two whole units with half of one left over.
    @Test("A rate that does not divide exactly reports the part left over")
    func inexactDivision() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(minorUnits: 10).scaled(by: "0.25")))

        #expect(amount == GBP(minorUnits: 2))
        #expect(remainder == "0.5")
    }

    // The amount truncates toward zero and the remainder takes the same sign, so the two together
    // account for the exact product: -2 and -0.5, never -3 and 0.5.
    @Test("A negative amount truncates toward zero")
    func negativeAmount() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(minorUnits: -10).scaled(by: "0.25")))

        #expect(amount == GBP(minorUnits: -2))
        #expect(remainder == "-0.5")
    }

    @Test("A negative rate negates the result")
    func negativeRate() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(minorUnits: 10).scaled(by: "-0.25")))

        #expect(amount == GBP(minorUnits: -2))
        #expect(remainder == "-0.5")
    }

    @Test("Two negatives make a positive")
    func negativeAmountAndRate() throws {
        let (amount, remainder) = try #require(inexactParts(GBP(minorUnits: -10).scaled(by: "-0.25")))

        #expect(amount == GBP(minorUnits: 2))
        #expect(remainder == "0.5")
    }

    // The largest amount is odd, so half of it leaves half a unit over. Scaling holds the product at a
    // wider precision than a minor unit, so a large amount scales without a false overflow.
    @Test("A large amount scales without a false overflow")
    func largeAmountScales() throws {
        let (amount, remainder) = try #require(inexactParts(GBP.max.scaled(by: "0.5")))

        #expect(amount == GBP(minorUnits: Int64.max / 2))
        #expect(remainder == "0.5")
    }

    // The smallest amount has no positive counterpart, so rebuilding it from a magnitude is the one
    // case that could overflow on the way back.
    @Test("The smallest amount scales")
    func smallestAmountScales() {
        #expect(GBP.min.scaled(by: "1") == .exact(GBP.min))
        #expect(GBP.min.scaled(by: "0.5") == .exact(GBP(minorUnits: Int64.min / 2)))
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
        #expect(GBP(minorUnits: 10).scaled(by: "0.25", rounding: rule) == expected)
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
        #expect(GBP(minorUnits: 9).scaled(by: "0.25", rounding: rule) == expected)
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
        #expect(GBP(minorUnits: 11).scaled(by: "0.25", rounding: rule) == expected)
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
        #expect(GBP(minorUnits: -10).scaled(by: "0.25", rounding: rule) == expected)
    }

    // Banker's rounding breaks a tie toward the even neighbor, so 2.5 and 3.5 both settle on an even
    // number rather than both going the same direction.
    @Test("An exact half rounds to even in both directions")
    func exactHalfRoundsToEven() {
        #expect(GBP(minorUnits: 10).scaled(by: "0.25", rounding: .toNearestOrEven) == GBP(minorUnits: 2))
        #expect(GBP(minorUnits: 14).scaled(by: "0.25", rounding: .toNearestOrEven) == GBP(minorUnits: 4))
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
        #expect(GBP(minorUnits: 8).scaled(by: "0.25", rounding: rule) == GBP(minorUnits: 2))
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
            blackHole(GBP.max.scaled(by: "2"))
        }
    }

    @Test("Scaling traps on underflow")
    func scalingTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min.scaled(by: "2"))
        }
    }

    @Test("A leftover reads back as a rate")
    func remainderReadsBackAsARate() throws {
        let (_, remainder) = try #require(inexactParts(GBP(minorUnits: 10).scaled(by: "0.25")))

        #expect(remainder == Rate.percent(50))
    }
}

private let threeHalves: Rate = "1.5"

// Three halves of this amount is exactly the largest amount, with a half left over, so truncating fits
// and only the rounding step passes the maximum. At file scope because an exit test runs in a child
// process, so its closure cannot capture a local.
private let threeHalvesOfThisIsTheLargestAmount = GBP(minorUnits: Int64.max / 3 * 2 + 1)

// An inexact result cannot be built from outside the module (that is what stops one claiming a
// remainder it does not have), so these tests read the parts back out rather than comparing against a
// constructed value.
private func inexactParts<Amount>(
    _ scaled: Scaled<Amount>
) -> (amount: Amount, remainder: Rate)? {
    guard case let .inexact(amount, remainder) = scaled else {
        return nil
    }

    return (amount, Rate(remainder))
}
