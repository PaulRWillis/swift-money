import SwiftMoneyCore
import Testing

@Suite("Rate Parsing Tests")
struct RateParsingTests {

    @Test("Decimal, percent, and fraction forms name the same rate")
    func formsAgree() throws {
        #expect(try #require(Rate(string: "0.175")) == Rate.basisPoints(1750))
        #expect(try #require(Rate(string: "1/4")) == Rate.percent(25))
        #expect(try #require(Rate(string: "5%")) == Rate.percent(5))
        #expect(try #require(Rate(string: "100")) == Rate.percent(10_000))   // "100" is the multiplier 100

        let fromPercent = try #require(Rate(string: "17.5%"))
        let fromDecimal = try #require(Rate(string: "0.175"))
        #expect(fromPercent == fromDecimal)
    }

    @Test("Signs and a leading point parse")
    func signsAndLeadingPoint() throws {
        #expect(try #require(Rate(string: "-0.05")) == Rate.percent(-5))
        #expect(try #require(Rate(string: ".5")) == Rate.percent(50))
    }

    @Test("An inexact fraction rounds by the caller's rule")
    func inexactFractionRounds() {
        #expect(Rate(string: "1/3", rounding: .down) != Rate(string: "1/3", rounding: .up))
    }

    @Test("Malformed strings return nil", arguments: [
        "", "abc", "1.2.3", "1e3", "1/0", "1/2/3", "1/3%", ".", "-", "%",
    ])
    func malformedReturnsNil(_ text: String) {
        #expect(Rate(string: text) == nil)
    }

    @Test("Exact string literals build the rate")
    func exactLiteralsBuild() {
        let fraction: Rate = "1/4"
        let percentage: Rate = "5%"
        let decimal: Rate = "0.175"
        #expect(fraction == Rate.percent(25))
        #expect(percentage == Rate.percent(5))
        #expect(decimal == Rate.basisPoints(1750))
    }

    @Test("A literal whose digits past the grid are all zero builds the rate")
    func trailingZerosPastTheGridStayExact() {
        #expect(Rate(stringLiteral: "0.5" + String(repeating: "0", count: 22)) == Rate.percent(50))
    }

    @Test("A percent literal is exact to the grid's last digit")
    func percentLiteralAtTheGridsLastDigit() throws {
        let smallest: Rate = "0.0000000000000001%"

        #expect(smallest == (try #require(Rate(string: "0.000000000000000001"))))
    }

    @Test("A percent literal one digit past the grid traps")
    func percentLiteralPastTheGridTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Rate(stringLiteral: "0.00000000000000001%"))
        }
    }

    @Test("A negative literal finer than the grid traps")
    func negativeOverlyPreciseLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Rate(stringLiteral: "-0.1234567890123456789"))
        }
    }

    // The nineteenth digit is exactly half a step, so each rule picks one of the two neighbors.
    @Test(
        "A string finer than the grid rounds by the caller's rule",
        arguments: [
            (RoundingRule.toNearestOrEven, "0.123456789012345678"),
            (.toNearestOrAwayFromZero, "0.123456789012345679"),
            (.towardZero, "0.123456789012345678"),
            (.up, "0.123456789012345679"),
        ]
    )
    func finerThanTheGridRounds(_ rule: RoundingRule, _ neighbor: String) throws {
        let expected = try #require(Rate(string: neighbor))

        #expect(Rate(string: "0.1234567890123456785", rounding: rule) == expected)
    }

    @Test("An inexact fraction literal traps")
    func inexactFractionLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Rate(stringLiteral: "1/3"))
        }
    }

    @Test("A literal finer than the grid traps")
    func overlyPreciseLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Rate(stringLiteral: "0.1234567890123456789"))
        }
    }

    @Test("A malformed literal traps")
    func malformedLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Rate(stringLiteral: "not a rate"))
        }
    }
}
