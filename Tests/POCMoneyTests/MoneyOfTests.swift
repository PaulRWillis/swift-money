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
            _ = GBP.max + GBP(1)
        }
    }

    @Test("Add traps on negative overflow")
    func addNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = GBP.min + GBP(-1)
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

    @Test("Addition in place traps on positive overflow")
    func additionInPlacePositiveOverflow() async {
        await #expect(processExitsWith: .failure) {
            var a = GBP.max
            a += GBP(1)
        }
    }

    @Test("Addition in place traps on negative overflow")
    func additionInPlaceNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            var a = GBP.min
            a += GBP(-1)
        }
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
            _ = GBP.max - GBP(-1)
        }
    }

    @Test("Subtract traps on negative overflow")
    func subtractNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = GBP.min - GBP(1)
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

    @Test("Subtraction in place traps on positive overflow")
    func subtractionInPlacePositiveOverflow() async {
        await #expect(processExitsWith: .failure) {
            var a = GBP.max
            a -= GBP(-1)
        }
    }

    @Test("Subtraction in place traps on negative overflow")
    func subtractionInPlaceNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            var a = GBP.min
            a -= GBP(1)
        }
    }
}
