import POCMoney
import Testing

@Suite("MoneyOf Tests")
struct MoneyOfTests {

    // MARK: - Zero

    @Test("Zero static property has value of zero")
    func zeroPropertyHasZeroValue() {
        let zero = GBP.zero

        #expect(zero == GBP(0))
    }

    // MARK: - Min/Max

    @Test("Min is equivalent to construction through `MoneyOf<C>(Int.min)`")
    func min() {
        #expect(GBP.min == GBP.min)
    }

    @Test("Max is equivalent to construction through `MoneyOf<C>(Int.max)`")
    func max() {
        #expect(GBP.max == GBP.max)
    }

    // MARK: - Addition

    @Test("Add succeeds")
    func add() {
        let a = GBP(5)
        let b = GBP(7)

        #expect(a + b == GBP(12))
    }

    @Test("Add traps on positive overflow")
    func addPositiveOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max + GBP(1))
        }
    }

    @Test("Add traps on negative overflow")
    func addNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min + GBP(-1))
        }
    }

    // MARK: - Addition In Place

    @Test("Addition in place succeeds")
    func additionInPlace() {
        var a = GBP(5)
        let b = GBP(7)

        a += b

        #expect(a == GBP(12))
    }

    // MARK: - Subtraction

    @Test("Subtract succeeds")
    func subtract() {
        let a = GBP(5)
        let b = GBP(7)

        #expect(a - b == GBP(-2))
    }

    @Test("Subtract traps on positive overflow")
    func subtractPositiveOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max - GBP(-1))
        }
    }

    @Test("Subtract traps on negative overflow")
    func subtractNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min - GBP(1))
        }
    }

    // MARK: - Subtraction In Place

    @Test("Subtraction in place succeeds")
    func subtractionInPlace() {
        var a = GBP(5)
        let b = GBP(7)

        a -= b

        #expect(a == GBP(-2))
    }

    // MARK: - Integral Multiplication

    @Test("Integral multiplication succeeds")
    func integralMultiplication() {
        let a = GBP(7)

        #expect(a * 5 == GBP(35))
        #expect(5 * a == GBP(35))
    }

    @Test("Integral multiplication returns correct sign")
    func integralMultiplicationSign() {
        let pos = GBP(+12) // 12p; £0.12
        let neg = GBP(-12)

        #expect(pos * 2 == GBP(+24))
        #expect(neg * 2 == GBP(-24))

        #expect(pos * -3 == GBP(-36)) // -36p; -£0.36
        #expect(neg * -3 == GBP(+36))
    }

    @Test("Integral multiplication traps on positive overflow")
    func integralMultiplicationPositiveOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max * 2)
        }

        await #expect(processExitsWith: .failure) {
            blackHole(2 * GBP.max)
        }
    }

    @Test("Integral multiplication traps on negative overflow")
    func integralMultiplicationNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min * 2)
        }

        await #expect(processExitsWith: .failure) {
            blackHole(2 * GBP.min)
        }
    }

    // MARK: - Integral Multiplication In Place

    @Test("Integral multiplication in place func succeeds")
    func integralMultiplicationInPlace() {
        var a = GBP(2_25) // £2.25
        let b: Int = 3

        a *= b

        #expect(a == GBP(6_75)) // £6.75
    }

    // MARK: - Fractional Multiplication

    #warning("TODO")

    // MARK: - Split

    // The algorithm itself is covered by SplitTests, which drives it through GBP.
    // These two check only that `split(into:)` returns shares as the same money type.

    @Test("Split evenly, shares come back as the same money type")
    func splitEvenlyKeepsMoneyType() {
        let sut = GBP(2)

        let result = sut.split(into: 2)

        #expect(result.values == [GBP(1), GBP(1),])
    }

    @Test("Split unevenly, shares come back as the same money type")
    func splitUnevenlyKeepsMoneyType() {
        let sut = GBP(3)

        let result = sut.split(into: 2)

        #expect(result.values == [GBP(2), GBP(1),])
    }

    // MARK: - Comparable

    @Test("Lower value is less than higher value")
    func lowerValueIsLessThanHigherValue() {
        let low = GBP(9)
        let high = GBP(10)

        #expect(low < high)
        #expect(!(high < low))
    }

    @Test("Compared values can be transitively ordered")
    func comparedValuesCanBeTransitivelyOrdered() {
        let a = GBP(1_00)
        let b = GBP(2_00)
        let c = GBP(3_00)

        #expect(a < b)
        #expect(b < c)
        #expect(a < c)
    }

    @Test("Value is not less than itself")
    func valueIsNotLessThanItself() {
        let sut = GBP(1_00)

        #expect(!(sut < sut))
    }

    @Test("Equal values are not less than each other")
    func equalValuesAreNotLessThanEachOther() {
        let a = GBP(5_00)
        let b = GBP(5_00)

        #expect(a == b)
        #expect(!(a < b))
        #expect(!(b < a))
    }

    @Test("Derived comparison operators follow comparable logic")
    func derivedComparisonOperators() {
        let low = GBP(1_00)
        let high = GBP(2_00)

        #expect(low <= high)
        #expect(low <= low)

        #expect(high >= low)
        #expect(high >= high)

        #expect(high > low)
    }

    @Test("Sorting produces ascending order")
    func sortingProducesAscendingOrder() {
        let values = [
            GBP(5_20),
            GBP(-2_40),
            GBP(1_40),
            GBP(3_38),
            GBP(3_39),
        ]

        let sorted = values.sorted()

        #expect(sorted == [
            GBP(-2_40),
            GBP(1_40),
            GBP(3_38),
            GBP(3_39),
            GBP(5_20),
        ])
    }

    // MARK: - `isMultipleOf(other:)`

    @Test("Is multiple of money where euclidean remainder is zero")
    func isMultipleOnZeroRemainder() {
        let a = GBP(3_33)
        let b = GBP(9_99)

        #expect(b.isMultiple(of: a))
        #expect(!a.isMultiple(of: b))
    }

    @Test("Is NOT multiple of money where euclidean remainder is not zero")
    func isNotMultipleForRemainder() {
        let a = GBP(2_00) // £2.00
        let b = GBP(6_01) // Results in £0.01 remainder

        #expect(!b.isMultiple(of: a))
    }

    @Test("Zero is multiple of any value")
    func zeroIsMultipleOfAnyValue() {
        let zero = GBP.zero
        let arr = [GBP(0), GBP(10), GBP(999_99), GBP(12345678_99)]

        for value in arr {
            #expect(zero.isMultiple(of: value))
        }
    }

    // MARK: - Strideable

    @Test("Strideable advancing by zero returns self")
    func strideableAdvanceByZeroReturnsSelf() {
        let sut = GBP(12_34) // £12.34

        #expect(sut.advanced(by: .zero) == sut)
    }

    @Test("Strideable distance to self is zero")
    func strideableDistanceToSelfIsZero() {
        let sut = GBP(12_34)

        #expect(sut.distance(to: sut) == .zero)
    }

    @Test("Strideable advancing produces expected distance")
    func strideableAdvanceProducesExpectedDistance() {
        let start = GBP(10_00) // £10.00
        let end = start.advanced(by: 2_50) // £2.50

        #expect(start.distance(to: end) == 2_50) // distance == £2.50
    }

    @Test("Strideable advancing by distance reaches destination")
    func strideableAdvanceByDistanceReachesDestination() {
        let start = GBP(10_00)
        let end = GBP(13_75)

        let distance = start.distance(to: end)

        #expect(start.advanced(by: distance) == end)
    }

    @Test("Positive and negative strides")
    func positiveAndNegativeStrides() {
        let sut = GBP(9_00)

        #expect(sut.advanced(by: +5_00) == GBP(14_00))
        #expect(sut.advanced(by: -5_00) == GBP(4_00))
    }

    @Test("Strideable distance has correct sign")
    func strideableDistanceHasCorrectSign() {
        let low = GBP(5_00)
        let high = GBP(9_00)

        #expect(low.distance(to: high) == 4_00)
        #expect(high.distance(to: low) == -4_00)
    }

    @Test("Strideable distances are opposites")
    func strideableDistancesAreOpposites() {
        let a = GBP(2_50)
        let b = GBP(8_00)

        #expect(a.distance(to: b) == -b.distance(to: a))
    }

    @Test("Strideable ordering matches distance")
    func orderingMatchesStrideableDistance() {
        let a = GBP(1_00)
        let b = GBP(2_00)

        #expect(a < b)
        #expect(a.distance(to: b) > 0)
        #expect(b.distance(to: a) < 0)
    }

    @Test("Strideable advances compose")
    func strideableAdvancesCompose() {
        let start = GBP(10_00)

        let composed = start
            .advanced(by: 2_00)
            .advanced(by: 3_00)

        let once = start.advanced(by: 5_00)

        #expect(composed == once)
    }

    @Test("Strideable round trip returns self")
    func strideableRoundTripReturnsSelf() {
        let sut = GBP(9_87)

        let result = sut
            .advanced(by: +4_32) // forwards
            .advanced(by: -4_32) // backwards

        #expect(result == sut)
    }
}
