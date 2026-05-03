import Testing
import SwiftMoney

@Suite("Rate+LosslessStringConvertible")
struct RateLosslessStringConvertibleTests {

    @Test("init parses '11/100'")
    func parseFraction() {
        let r = Rate("11/100")
        #expect(r?.numeratorValue == 11)
        #expect(r?.denominatorValue == 100)
    }

    @Test("init parses negative '-1/10'")
    func parseNegative() {
        let r = Rate("-1/10")
        #expect(r?.numeratorValue == -1)
        #expect(r?.denominatorValue == 10)
    }

    @Test("init reduces '22/200' to 11/100")
    func parseReduces() {
        let r = Rate("22/200")
        #expect(r?.numeratorValue == 11)
        #expect(r?.denominatorValue == 100)
    }

    @Test("init parses '1/1'")
    func parseOne() {
        let r = Rate("1/1")
        #expect(r?.numeratorValue == 1)
        #expect(r?.denominatorValue == 1)
    }

    @Test("init parses '0/1' (zero rate)")
    func parseZero() {
        let r = Rate("0/1")
        #expect(r?.numeratorValue == 0)
        #expect(r?.denominatorValue == 1)
    }

    @Test("round-trip through description")
    func roundTrip() throws {
        let original = try #require(Rate(numerator: 23, denominator: 1_000_000))
        let parsed = Rate(original.description)
        #expect(parsed == original)
    }

    @Test("init returns nil for empty string")
    func emptyString() {
        #expect(Rate("") == nil)
    }

    @Test("init returns nil for missing denominator 'abc'")
    func noSlash() {
        #expect(Rate("abc") == nil)
    }

    @Test("init returns nil for non-numeric '3/abc'")
    func nonNumericDenominator() {
        #expect(Rate("3/abc") == nil)
    }

    @Test("init returns nil for zero denominator '3/0'")
    func zeroDenominator() {
        #expect(Rate("3/0") == nil)
    }

    @Test("init returns nil for negative denominator '3/-1'")
    func negativeDenominator() {
        #expect(Rate("3/-1") == nil)
    }

    @Test("init returns nil for multiple slashes '1/2/3'")
    func multipleSlashes() {
        #expect(Rate("1/2/3") == nil)
    }

    @Test("init returns nil for Int64.min numerator")
    func int64MinNumerator() {
        #expect(Rate("\(Int64.min)/1") == nil)
    }

    // MARK: - Rate.zero

    @Test(".zero is 0/1")
    func zeroConstant() {
        #expect(Rate.zero.numeratorValue == 0)
        #expect(Rate.zero.denominatorValue == 1)
    }

    @Test(".zero equals Rate from string '0/1'")
    func zeroEqualsStringParsed() {
        #expect(Rate.zero == Rate("0/1"))
    }
}
