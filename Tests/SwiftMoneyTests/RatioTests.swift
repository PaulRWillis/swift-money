import SwiftMoney
import Testing

@Suite("Ratio Tests")
struct RatioTests {

    // MARK: - Canonical form

    // Storage is private, so reduction is observable only through equality and description. That is
    // the point: a caller cannot depend on the representation, only on the value.
    @Test("Equivalent fractions are equal")
    func equivalentFractionsAreEqual() {
        #expect(Ratio(22, 200) == Ratio(11, 100))
        #expect(Ratio(6, 4) == Ratio(3, 2))
        #expect(Ratio(-22, 200) == Ratio(-11, 100))
    }

    @Test("Equivalent fractions hash alike")
    func equivalentFractionsHashAlike() {
        #expect(Set([Ratio(22, 200), Ratio(11, 100), Ratio(3, 2)]).count == 2)
    }

    @Test("Different fractions are not equal")
    func differentFractionsAreNotEqual() {
        #expect(Ratio(1, 3) != Ratio(1, 2))
        #expect(Ratio(1, 3) != Ratio(-1, 3))
    }

    @Test("Reduction is visible in the description")
    func reductionIsVisibleInDescription() {
        #expect(String(describing: Ratio(22, 200)) == "11/100")
        #expect(String(describing: Ratio(6, 4)) == "3/2")
    }

    // MARK: - Zero

    @Test("Every representation of zero is the same ratio")
    func zeroIsCanonical() {
        #expect(Ratio(0, 5) == Ratio(0, 1))
        #expect(Ratio(0, 997) == Ratio(0, 1))
        #expect(String(describing: Ratio(0, 5)) == "0/1")
    }

    // MARK: - Sign

    @Test("The sign is carried by the numerator")
    func signIsCarriedByTheNumerator() {
        #expect(String(describing: Ratio(-7, 40)) == "-7/40")
        #expect(String(describing: Ratio(7, 40)) == "7/40")
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

}
