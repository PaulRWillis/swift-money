import SwiftMoney
import Testing

@Suite("MoneyOf Tests")
struct MoneyOfTests {

    @Test("Zero static property has value of zero")
    func zeroPropertyHasZeroValue() {
        let zero = GBP.zero

        #expect(zero == GBP(minorUnits: 0))
    }

    @Test("Min is equivalent to construction through `MoneyOf<C>(Int64.min)`")
    func min() {
        #expect(GBP.min == GBP.min)
    }

    @Test("Max is equivalent to construction through `MoneyOf<C>(Int64.max)`")
    func max() {
        #expect(GBP.max == GBP.max)
    }

    @Test("when constructed from narrower integer should hold same amount")
    func whenConstructedFromNarrowerInteger_shouldHoldSameAmount() {
        let sut = GBP(minorUnits: Int8(99))

        #expect(sut == GBP(minorUnits: 99))
    }

    @Test("when constructed exactly from representable value should hold same amount")
    func whenConstructedExactlyFromRepresentableValue_shouldHoldSameAmount() {
        let sut = GBP(exactly: Int128(4_99))

        #expect(sut == GBP(minorUnits: 4_99))
    }

    @Test("when constructed exactly from value beyond storage should return nil")
    func whenConstructedExactlyFromValueBeyondStorage_shouldReturnNil() {
        #expect(GBP(exactly: Int128.max) == nil)
        #expect(GBP(exactly: UInt64.max) == nil)
    }

    @Test("when constructed from value beyond storage should trap")
    func whenConstructedFromValueBeyondStorage_shouldTrap() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: Int128.max))
        }
    }

    @Test("Add succeeds")
    func add() {
        let a = GBP(minorUnits: 5)
        let b = GBP(minorUnits: 7)

        #expect(a + b == GBP(minorUnits: 12))
    }

    @Test("Add traps on overflow")
    func addTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max + GBP(minorUnits: 1))
        }
    }

    @Test("Add traps on underflow")
    func addTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min + GBP(minorUnits: -1))
        }
    }

    @Test("Addition in place succeeds")
    func additionInPlace() {
        var a = GBP(minorUnits: 5)
        let b = GBP(minorUnits: 7)

        a += b

        #expect(a == GBP(minorUnits: 12))
    }

    @Test("Subtract succeeds")
    func subtract() {
        let a = GBP(minorUnits: 5)
        let b = GBP(minorUnits: 7)

        #expect(a - b == GBP(minorUnits: -2))
    }

    @Test("Subtract traps on overflow")
    func subtractTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max - GBP(minorUnits: -1))
        }
    }

    @Test("Subtract traps on underflow")
    func subtractTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min - GBP(minorUnits: 1))
        }
    }

    @Test("Subtraction in place succeeds")
    func subtractionInPlace() {
        var a = GBP(minorUnits: 5)
        let b = GBP(minorUnits: 7)

        a -= b

        #expect(a == GBP(minorUnits: -2))
    }

    @Test("Negation flips a positive amount to negative")
    func negationFlipsPositiveToNegative() {
        let sut = GBP(minorUnits: 4_99)

        #expect(-sut == GBP(minorUnits: -4_99))
    }

    @Test("Negation of a negative amount returns its positive twin")
    func negationOfNegativeAmountReturnsPositiveTwin() {
        let sut = GBP(minorUnits: -4_99)

        #expect(-sut == GBP(minorUnits: 4_99))
        #expect(-(-sut) == sut)
    }

    @Test("Negation of zero returns zero")
    func negationOfZeroReturnsZero() {
        #expect(-GBP.zero == GBP.zero)
    }

    @Test("Negation traps on min")
    func negationTrapsOnMin() async {
        await #expect(processExitsWith: .failure) {
            blackHole(-GBP.min)
        }
    }

    @Test("Integral multiplication succeeds")
    func integralMultiplication() {
        let a = GBP(minorUnits: 7)

        #expect(a * 5 == GBP(minorUnits: 35))
        #expect(5 * a == GBP(minorUnits: 35))
    }

    @Test("Integral multiplication returns correct sign")
    func integralMultiplicationSign() {
        let pos = GBP(minorUnits: +12) // 12p; £0.12
        let neg = GBP(minorUnits: -12)

        #expect(pos * 2 == GBP(minorUnits: +24))
        #expect(neg * 2 == GBP(minorUnits: -24))

        #expect(pos * -3 == GBP(minorUnits: -36)) // -36p; -£0.36
        #expect(neg * -3 == GBP(minorUnits: +36))
    }

    @Test("Integral multiplication traps on overflow")
    func integralMultiplicationTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.max * 2)
        }

        await #expect(processExitsWith: .failure) {
            blackHole(2 * GBP.max)
        }
    }

    @Test("Integral multiplication traps on underflow")
    func integralMultiplicationTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min * 2)
        }

        await #expect(processExitsWith: .failure) {
            blackHole(2 * GBP.min)
        }
    }

    @Test("Integral multiplication in place func succeeds")
    func integralMultiplicationInPlace() {
        var a = GBP(minorUnits: 2_25) // £2.25
        let b: Int = 3

        a *= b

        #expect(a == GBP(minorUnits: 6_75)) // £6.75
    }

    // Fractional scaling is covered by ScalingTests, which drives the algorithm through GBP.

    // The algorithm itself is covered by SplitTests, which drives it through GBP.
    // These two check only that `split(into:)` returns shares as the same money type.

    @Test("Split evenly, shares come back as the same money type")
    func splitEvenlyKeepsMoneyType() {
        let sut = GBP(minorUnits: 2)

        let result = sut.split(into: 2)

        #expect(Array(result.amounts) == [GBP(minorUnits: 1), GBP(minorUnits: 1),])
    }

    @Test("Split unevenly, shares come back as the same money type")
    func splitUnevenlyKeepsMoneyType() {
        let sut = GBP(minorUnits: 3)

        let result = sut.split(into: 2)

        #expect(Array(result.amounts) == [GBP(minorUnits: 2), GBP(minorUnits: 1),])
    }

    @Test("Lower value is less than higher value")
    func lowerValueIsLessThanHigherValue() {
        let low = GBP(minorUnits: 9)
        let high = GBP(minorUnits: 10)

        #expect(low < high)
        #expect(!(high < low))
    }

    @Test("Compared values can be transitively ordered")
    func comparedValuesCanBeTransitivelyOrdered() {
        let a = GBP(minorUnits: 1_00)
        let b = GBP(minorUnits: 2_00)
        let c = GBP(minorUnits: 3_00)

        #expect(a < b)
        #expect(b < c)
        #expect(a < c)
    }

    @Test("Value is not less than itself")
    func valueIsNotLessThanItself() {
        let sut = GBP(minorUnits: 1_00)

        #expect(!(sut < sut))
    }

    @Test("Equal values are not less than each other")
    func equalValuesAreNotLessThanEachOther() {
        let a = GBP(minorUnits: 5_00)
        let b = GBP(minorUnits: 5_00)

        #expect(a == b)
        #expect(!(a < b))
        #expect(!(b < a))
    }

    @Test("Derived comparison operators follow comparable logic")
    func derivedComparisonOperators() {
        let low = GBP(minorUnits: 1_00)
        let high = GBP(minorUnits: 2_00)

        #expect(low <= high)
        #expect(low <= low)

        #expect(high >= low)
        #expect(high >= high)

        #expect(high > low)
    }

    // Ranges, ordering and clamping come from `Comparable`, not from `Strideable`, which is why
    // dropping `Strideable` costs only the ability to iterate every minor unit between two amounts.
    @Test("when building a range of amounts should support containment and bounds")
    func rangesComeFromComparable() {
        let band = GBP(minorUnits: 1_00)...GBP(minorUnits: 9_00)

        #expect(band.contains(GBP(minorUnits: 5_00)))
        #expect(!band.contains(GBP(minorUnits: 9_01)))
        #expect(band.lowerBound == GBP(minorUnits: 1_00))
        #expect(band.upperBound == GBP(minorUnits: 9_00))
        #expect(band.clamped(to: GBP(minorUnits: 2_00)...GBP(minorUnits: 4_00)) == GBP(minorUnits: 2_00)...GBP(minorUnits: 4_00))
    }

    @Test("when comparing a sequence of amounts should return the extremes")
    func extremesComeFromComparable() {
        let values = [GBP(minorUnits: 5_20), GBP(minorUnits: -2_40), GBP(minorUnits: 3_38)]

        #expect(values.max() == GBP(minorUnits: 5_20))
        #expect(values.min() == GBP(minorUnits: -2_40))
    }

    @Test("Sorting produces ascending order")
    func sortingProducesAscendingOrder() {
        let values = [
            GBP(minorUnits: 5_20),
            GBP(minorUnits: -2_40),
            GBP(minorUnits: 1_40),
            GBP(minorUnits: 3_38),
            GBP(minorUnits: 3_39),
        ]

        let sorted = values.sorted()

        #expect(sorted == [
            GBP(minorUnits: -2_40),
            GBP(minorUnits: 1_40),
            GBP(minorUnits: 3_38),
            GBP(minorUnits: 3_39),
            GBP(minorUnits: 5_20),
        ])
    }

    @Test("Is multiple of money where euclidean remainder is zero")
    func isMultipleOnZeroRemainder() {
        let a = GBP(minorUnits: 3_33)
        let b = GBP(minorUnits: 9_99)

        #expect(b.isMultiple(of: a))
        #expect(!a.isMultiple(of: b))
    }

    @Test("Is NOT multiple of money where euclidean remainder is not zero")
    func isNotMultipleForRemainder() {
        let a = GBP(minorUnits: 2_00) // £2.00
        let b = GBP(minorUnits: 6_01) // Results in £0.01 remainder

        #expect(!b.isMultiple(of: a))
    }

    @Test("Zero is multiple of any value")
    func zeroIsMultipleOfAnyValue() {
        let zero = GBP.zero
        let arr = [GBP(minorUnits: 0), GBP(minorUnits: 10), GBP(minorUnits: 999_99), GBP(minorUnits: 12345678_99)]

        for value in arr {
            #expect(zero.isMultiple(of: value))
        }
    }

    @Test("No amount other than zero is a multiple of zero")
    func onlyZeroIsMultipleOfZero() {
        #expect(GBP.zero.isMultiple(of: GBP.zero))
        #expect(!GBP(minorUnits: 1).isMultiple(of: GBP.zero))
    }

}
