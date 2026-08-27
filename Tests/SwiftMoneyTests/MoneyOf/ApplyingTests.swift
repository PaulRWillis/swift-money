import SwiftMoney
import Testing

@Suite("Applying Tests")
struct ApplyingTests {

    @Test("A rate that divides exactly gives the exact amount, whatever the rule", arguments: everyRule)
    func exactDivision(rule: RoundingRule) {
        #expect(GBP(minorUnits: 10_00).applying("0.2").rounded(rule) == GBP(minorUnits: 2_00))
    }

    @Test("A whole rate multiplies")
    func wholeRate() {
        #expect(GBP(minorUnits: 1_00).applying("3").rounded(.toNearestOrEven) == GBP(minorUnits: 3_00))
    }

    @Test("Scaling by zero is zero")
    func zeroRate() {
        #expect(GBP(minorUnits: 10_00).applying("0").rounded(.toNearestOrEven) == GBP.zero)
    }

    @Test("Scaling zero is zero")
    func zeroAmount() throws {
        let third = try #require(Rate(string: "1/3"))

        #expect(GBP.zero.applying(third).rounded(.toNearestOrEven) == GBP.zero)
    }

    // A quarter of 10 is 2.5: exactly between two whole units, which is where the rules differ most.
    @Test(
        "Every rule settles an exact half",
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
        #expect(GBP(minorUnits: 10).applying("0.25").rounded(rule) == expected)
    }

    // A quarter of 9 is 2.25, so the nearest whole unit is the one it was truncated to.
    @Test(
        "Every rule settles a fraction below a half",
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
        #expect(GBP(minorUnits: 9).applying("0.25").rounded(rule) == expected)
    }

    // A quarter of 11 is 2.75, so both nearest rules step where they did not at 2.25.
    @Test(
        "Every rule settles a fraction above a half",
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
        #expect(GBP(minorUnits: 11).applying("0.25").rounded(rule) == expected)
    }

    // A quarter of -10 is -2.5. This is where `.down` and `.towardZero` part company, and where
    // `.awayFromZero` and `.up` do: a sign error in a rule shows up here and nowhere else.
    @Test(
        "Every rule settles a negative exact half",
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
        #expect(GBP(minorUnits: -10).applying("0.25").rounded(rule) == expected)
    }

    // Banker's rounding breaks a tie toward the even neighbor, so 2.5 and 3.5 both settle on an even
    // number rather than both going the same direction.
    @Test("An exact half settles to even in both directions")
    func exactHalfRoundsToEven() {
        #expect(GBP(minorUnits: 10).applying("0.25").rounded(.toNearestOrEven) == GBP(minorUnits: 2))
        #expect(GBP(minorUnits: 14).applying("0.25").rounded(.toNearestOrEven) == GBP(minorUnits: 4))
    }

    @Test("A rule cannot change an exact result", arguments: everyRule)
    func exactResultsAreUnchanged(rule: RoundingRule) {
        #expect(GBP(minorUnits: 8).applying("0.25").rounded(rule) == GBP(minorUnits: 2))
    }

    @Test("A negative amount settles by magnitude")
    func negativeAmount() {
        // -10 × 0.25 = -2.5, away from zero settles to -3.
        #expect(GBP(minorUnits: -10).applying("0.25").rounded(.awayFromZero) == GBP(minorUnits: -3))
    }

    @Test("A negative rate negates the result")
    func negativeRate() {
        #expect(GBP(minorUnits: 10).applying("-0.25").rounded(.towardZero) == GBP(minorUnits: -2))
    }

    @Test("The largest and smallest amounts scale")
    func extremes() {
        #expect(GBP.min.applying("1").rounded(.toNearestOrEven) == GBP.min)
        #expect(GBP.min.applying("0.5").rounded(.toNearestOrEven) == GBP(minorUnits: Int64.min / 2))
        // max is odd: max × 0.5 = …903.5, which banker's rounding settles to the even …904.
        #expect(GBP.max.applying("0.5").rounded(.toNearestOrEven) == GBP(minorUnits: Int64.max / 2 + 1))
    }

    @Test("Truncating reaches the largest amount exactly")
    func truncatingReachesTheLargestAmount() {
        #expect(threeHalvesOfThisIsTheLargestAmount.applying(threeHalves).rounded(.towardZero) == GBP.max)
    }

    @Test("Settling past the range traps, where truncating would not")
    func roundingTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(threeHalvesOfThisIsTheLargestAmount.applying(threeHalves).rounded(.awayFromZero))
        }
    }

    @Test("Settling a scaled amount past the range traps")
    func settlingTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max.applying("2").rounded(.toNearestOrEven))
        }
    }

    @Test("Settling a scaled amount below the range traps")
    func settlingTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min.applying("2").rounded(.toNearestOrEven))
        }
    }

    @Test("A runtime-currency amount scales and keeps its currency")
    func runtimeCurrency() {
        let money = Money(minorUnits: 10, currency: .gbp)

        #expect(money.applying("0.25").rounded(.up) == Money(minorUnits: 3, currency: .gbp))
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

private let threeHalves: Rate = "1.5"

// Three halves of this amount is exactly the largest amount, with a half left over, so truncating fits
// and only the rounding step passes the maximum. At file scope because an exit test runs in a child
// process, so its closure cannot capture a local.
private let threeHalvesOfThisIsTheLargestAmount = GBP(minorUnits: Int64.max / 3 * 2 + 1)
