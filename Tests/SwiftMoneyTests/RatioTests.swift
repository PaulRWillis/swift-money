import SwiftMoney
import Testing

@Suite("Ratio Tests")
struct RatioTests {

    // MARK: - Canonical form

    // Storage is private, so reduction is observable only through equality and description. That is
    // the point: a caller cannot depend on the representation, only on the value.
    @Test("Equivalent fractions are equal")
    func equivalentFractionsAreEqual() {
        #expect("22/200" as Ratio == "11/100")
        #expect("6/4" as Ratio == "3/2")
        #expect("-22/200" as Ratio == "-11/100")
    }

    @Test("Equivalent fractions hash alike")
    func equivalentFractionsHashAlike() {
        #expect(Set<Ratio>(["22/200", "11/100", "3/2"]).count == 2)
    }

    @Test("Different fractions are not equal")
    func differentFractionsAreNotEqual() {
        #expect("1/3" as Ratio != "1/2")
        #expect("1/3" as Ratio != "-1/3")
    }

    @Test("Reduction is visible in the description")
    func reductionIsVisibleInDescription() {
        #expect(String(describing: "22/200" as Ratio) == "11/100")
        #expect(String(describing: "6/4" as Ratio) == "3/2")
    }

    // MARK: - Zero

    @Test("Every representation of zero is the same ratio")
    func zeroIsCanonical() {
        #expect("0/5" as Ratio == "0/1")
        #expect("0/997" as Ratio == "0/1")
        #expect(String(describing: "0/5" as Ratio) == "0/1")
    }

    // MARK: - Sign

    @Test("The sign is carried by the numerator")
    func signIsCarriedByTheNumerator() throws {
        let negative = try #require(Ratio(exactly: -7, over: 40))
        let positive = try #require(Ratio(exactly: 7, over: 40))

        #expect(String(describing: negative) == "-7/40")
        #expect(String(describing: positive) == "7/40")
    }

    // MARK: - Extremes

    // Int64.min would overflow a naive `abs`-based reduction. Computing the greatest common divisor on
    // magnitudes avoids that, and a positive denominator means the numerator is never negated.
    @Test("Int64.min is representable and reduces")
    func int64MinIsRepresentable() {
        let smallest = Ratio.Numerator(.min)

        #expect(String(describing: Ratio(smallest, 1)) == "\(Int64.min)/1")
        #expect(String(describing: Ratio(smallest, 2)) == "\(Int64.min / 2)/1")
        #expect(String(describing: Ratio(smallest, 4)) == "\(Int64.min / 4)/1")
    }

    @Test("Int64.min stays irreducible against an odd denominator")
    func int64MinAgainstAnOddDenominator() {
        #expect(String(describing: Ratio(Ratio.Numerator(.min), 3)) == "\(Int64.min)/3")
    }

    @Test("Int64.max reduces against itself")
    func int64MaxReduces() throws {
        let largest = Ratio.Numerator(.max)
        let largestDenominator = try #require(Ratio.Denominator(exactly: .max))

        #expect(Ratio(largest, largestDenominator) == Ratio(1, 1))
        #expect(String(describing: Ratio(largest, 1)) == "\(Int64.max)/1")
    }

    // MARK: - Construction from runtime values

    @Test("A ratio can be built from values that are not literals")
    func builtFromRuntimeValues() throws {
        let rawNumerator: Int64 = 7
        let rawDenominator: Int64 = 40

        let denominator = try #require(Ratio.Denominator(exactly: rawDenominator))
        let ratio = Ratio(Ratio.Numerator(rawNumerator), denominator)

        #expect(ratio == Ratio(7, 40))
    }

    @Test(
        "Every numerator makes a ratio over one",
        arguments: [0, 1, -1, 7, -7, Int64.max, Int64.min]
    )
    func everyNumeratorMakesARatio(_ raw: Int64) throws {
        let ratio = try #require(Ratio(exactly: raw, over: 1))

        #expect(String(describing: ratio) == "\(raw)/1")
    }

    @Test(
        "Every positive denominator makes a ratio",
        arguments: [1, 2, 40, 100, 1_000, Int64.max]
    )
    func everyPositiveDenominatorMakesARatio(_ raw: Int64) throws {
        let ratio = try #require(Ratio(exactly: 1, over: raw))

        #expect(String(describing: ratio) == "1/\(raw)")
    }

    @Test(
        "A denominator below one makes no ratio",
        arguments: [0, -1, -40, Int64.min]
    )
    func denominatorBelowOneMakesNoRatio(_ raw: Int64) {
        #expect(Ratio(exactly: 1, over: raw) == nil)
    }

    @Test("Creation from integers reduces to lowest terms")
    func creationFromIntegersReduces() throws {
        let ratio = try #require(Ratio(exactly: 22, over: 200))

        #expect(String(describing: ratio) == "11/100")
    }

    @Test("A zero numerator is valid, where a zero denominator is not")
    func zeroNumeratorIsValidZeroDenominatorIsNot() throws {
        let zero = try #require(Ratio(exactly: 0, over: 40))

        #expect(String(describing: zero) == "0/1")
        #expect(Ratio(exactly: 40, over: 0) == nil)
    }

    @Test(
        "A fraction string is the fraction it writes, in lowest terms",
        arguments: [
            ("1/3", "1/3"),
            ("7/40", "7/40"),
            ("-7/40", "-7/40"),
            ("+1/3", "1/3"),
            ("007/040", "7/40"),
            ("22/200", "11/100"),
            ("0/5", "0/1"),
            ("9223372036854775808/2", "4611686018427387904/1"),   // reduces into Int64 range
        ]
    )
    func fractionStringParses(_ string: String, _ expected: String) throws {
        let parsed = try #require(Ratio(string: string))

        #expect(String(describing: parsed) == expected)
    }

    @Test("The smallest numerator parses and reduces")
    func smallestNumeratorParses() throws {
        let parsed = try #require(Ratio(string: "-9223372036854775808/2"))

        #expect(String(describing: parsed) == "\(Int64.min / 2)/1")
    }

    @Test(
        "A string that is not a fraction makes no ratio",
        arguments: [
            "",
            "/",
            "1/",
            "/3",
            "1/0",
            "0/0",
            "1/-3",
            "-1/-3",
            "a/3",
            "1/3x",
            " 1/3",
            "1/3 ",
            "1//3",
            "1/2/3",
            "1.5/2",
            "9223372036854775808/3",       // a numerator with no positive Int64
            "1/9223372036854775808",       // a denominator past Int64.max
            "½",                           // a vulgar fraction is not ASCII
            "１/３",                       // fullwidth digits
            "−1/3",                        // a Unicode minus is not "-"
        ]
    )
    func invalidFractionStringMakesNoRatio(_ string: String) {
        #expect(Ratio(string: string) == nil)
    }

    @Test(
        "A parsed ratio's description parses back to the same ratio",
        arguments: ["7/40", "-7/40", "22/200"]
    )
    func descriptionRoundTrips(_ string: String) throws {
        let parsed = try #require(Ratio(string: string))

        #expect(Ratio(string: String(describing: parsed)) == parsed)
    }

    @Test(
        "A decimal string is an exact fraction, in lowest terms",
        arguments: [
            ("1.2345", "2469/2000"),
            ("0.1", "1/10"),
            ("0.5", "1/2"),
            (".5", "1/2"),
            ("-0.25", "-1/4"),
            ("2", "2/1"),
            ("-2", "-2/1"),
            ("-9223372036854775808", "-9223372036854775808/1"),   // Int64.min
            ("0", "0/1"),
            ("-0", "0/1"),
            ("1.50", "3/2"),
            ("0.000000000000000001", "1/1000000000000000000"),   // eighteen places
            ("0.0000000000000000005", "1/2000000000000000000"),  // nineteen, reducing into range
        ]
    )
    func decimalStringParsesExactly(_ string: String, _ expected: String) throws {
        let parsed = try #require(Ratio(string: string))

        #expect(String(describing: parsed) == expected)
    }

    // The classic floating-point trap, exact here: 0.1 is one tenth, and a truncated third is
    // itself rather than the fraction it approximates.
    @Test("A truncated decimal is itself, never the fraction it approximates")
    func truncatedDecimalIsExact() throws {
        let parsed = try #require(Ratio(string: "0.333333"))
        let third = try #require(Ratio(exactly: 1, over: 3))

        #expect(parsed != third)
        #expect(String(describing: parsed) == "333333/1000000")
    }

    @Test(
        "A string that is not a decimal makes no ratio",
        arguments: [
            "4.",
            ".",
            "1.2.3",
            "1..2",
            "-",
            "+",
            "--1",
            "1.2a",
            "1,5",
            "0.５",                     // a fullwidth digit
            "0.00000000000000000051",   // twenty places, and 51/10^20 has no Int64 form
            "99999999999999999999",     // past Int64.max, and irreducible
        ]
    )
    func invalidDecimalStringMakesNoRatio(_ string: String) {
        #expect(Ratio(string: string) == nil)
    }

    @Test(
        "A percent string is an exact fraction, in lowest terms",
        arguments: [
            ("17.5%", "7/40"),
            ("50%", "1/2"),
            ("100%", "1/1"),
            ("200%", "2/1"),
            ("-50%", "-1/2"),
            ("0.5%", "1/200"),
            (".5%", "1/200"),
            ("12.34%", "617/5000"),
            ("0%", "0/1"),
        ]
    )
    func percentStringParsesExactly(_ string: String, _ expected: String) throws {
        let parsed = try #require(Ratio(string: string))

        #expect(String(describing: parsed) == expected)
    }

    @Test("The string and integer faces build the same ratio")
    func stringAndIntegerFacesAgree() throws {
        let fromString = try #require(Ratio(string: "17.5%"))
        let fromIntegers = try #require(Ratio(exactly: 7, over: 40))

        #expect(fromString == fromIntegers)
    }

    @Test(
        "A string that is not a percent makes no ratio",
        arguments: [
            "%",
            "5%%",
            "1/3%",
            "17.5% ",
            "% 5",
            "5 %",
            "0.00000000000000001%",   // 1/10^19, past what an Int64 denominator holds
        ]
    )
    func invalidPercentStringMakesNoRatio(_ string: String) {
        #expect(Ratio(string: string) == nil)
    }

    @Test("A valid string literal creates a ratio")
    func validStringLiteral() throws {
        let vat: Ratio = "17.5%"
        let expected = try #require(Ratio(string: "17.5%"))

        #expect(vat == expected)
    }

    // Malformed, zero denominator, negative denominator: all one trap, in the literal's delegation
    // to `init(string:)`.
    @Test(
        "A literal that is not a ratio traps",
        arguments: ["not a ratio", "1/0", "1/-3"]
    )
    func invalidLiteralTraps(_ string: String) async {
        await #expect(processExitsWith: .failure) { [string] in
            blackHole(Ratio(stringLiteral: string))
        }
    }
}
