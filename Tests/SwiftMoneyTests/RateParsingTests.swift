import SwiftMoney
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
