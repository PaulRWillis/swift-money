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
}
