import SwiftMoneyCore
import Testing

@Suite("Rate fraction parsing")
struct RateFractionParsingTests {

    static let oneThird = "0.333333333333333333"

    @Test("A point in either integer is refused", arguments: ["1.5/3", "1/1.5", "1./3", "1/.5"])
    func pointIsRefused(_ text: String) {
        #expect(Rate(string: text) == nil)
    }

    @Test("A plus sign on either integer is accepted", arguments: ["+1/3", "1/+3", "+1/+3"])
    func plusSignIsAccepted(_ text: String) throws {
        let expected = try #require(Rate(string: Self.oneThird))

        #expect(Rate(string: text) == expected)
    }

    @Test("A doubled sign is refused", arguments: ["--1/3", "+-1/3", "-+1/3", "1/--3", "1/++3"])
    func doubledSignIsRefused(_ text: String) {
        #expect(Rate(string: text) == nil)
    }

    @Test("A sign with no digits is refused", arguments: ["-/3", "+/3", "1/+", "1/-"])
    func bareSignIsRefused(_ text: String) {
        #expect(Rate(string: text) == nil)
    }

    @Test("An empty integer is refused", arguments: ["/3", "1/", "/"])
    func emptyIntegerIsRefused(_ text: String) {
        #expect(Rate(string: text) == nil)
    }

    @Test("Whitespace around either integer is refused", arguments: [" 1/3", "1 /3", "1/ 3", "1/3 "])
    func whitespaceIsRefused(_ text: String) {
        #expect(Rate(string: text) == nil)
    }

    @Test(
        "Leading zeros are accepted, however many",
        arguments: ["0001/3", "1/0003", "0000000000000000000000000000000000000000001/3"]
    )
    func leadingZerosAreAccepted(_ text: String) throws {
        let expected = try #require(Rate(string: Self.oneThird))

        #expect(Rate(string: text) == expected)
    }

    @Test("The largest whole numerator a rate holds parses exactly")
    func largestWholeNumerator() throws {
        let expected = try #require(Rate(string: "170141183460469231731"))

        #expect(Rate(string: "170141183460469231731/1") == expected)
    }

    @Test("The smallest whole numerator a rate holds parses exactly")
    func smallestWholeNumerator() throws {
        let expected = try #require(Rate(string: "-170141183460469231731"))

        #expect(Rate(string: "-170141183460469231731/1") == expected)
    }

    @Test(
        "A numerator past the whole numbers a rate holds is refused",
        arguments: ["170141183460469231732/1", "-170141183460469231732/1"]
    )
    func numeratorPastTheRateIsRefused(_ text: String) {
        #expect(Rate(string: text) == nil)
    }

    @Test("A numerator past the rate is refused even when the fraction fits")
    func numeratorPastTheRateIsRefusedWhateverTheDenominator() {
        #expect(Rate(string: "170141183460469231732/2") == nil)
    }

    @Test(
        "A numerator past 128 bits is refused",
        arguments: [
            "170141183460469231731687303715884105728/1",
            "-170141183460469231731687303715884105729/1",
            "1000000000000000000000000000000000000000000/1",
        ]
    )
    func numeratorPast128BitsIsRefused(_ text: String) {
        #expect(Rate(string: text) == nil)
    }

    @Test("The largest 128-bit denominator rounds the rate to zero")
    func largest128BitDenominator() throws {
        let zero = try #require(Rate(string: "0"))

        #expect(Rate(string: "1/170141183460469231731687303715884105727") == zero)
    }

    @Test(
        "A denominator past 128 bits is refused",
        arguments: [
            "1/170141183460469231731687303715884105728",
            "1/1000000000000000000000000000000000000000000",
        ]
    )
    func denominatorPast128BitsIsRefused(_ text: String) {
        #expect(Rate(string: text) == nil)
    }
}
