import POCMoney
import Testing

@Suite("Money Tests")
struct MoneyTests {

    // MARK: - Addition

    @Test("Add same currency succeeds")
    func addSameCurrency() {
        let a = Money(5, currency: .eur)
        let b = Money(7, currency: .eur)

        #expect(a + b == Money(12, currency: .eur))
    }

    @Test("Adding same currency to optional money succeeds")
    func addSameCurrencyToOptional() {
        let a = Money(3, currency: .gbp)
        let b = Money(2, currency: .gbp)
        let c = Money(6, currency: .gbp)

        #expect((a + b) + c == Money(11, currency: .gbp))
        #expect(c + (a + b) == Money(11, currency: .gbp))
    }

    @Test("Add returns nil on positive overflow")
    func addPositiveOverflow() {
        let a = Money(Int.max, currency: .gbp)
        let b = Money(1, currency: .gbp)

        #expect(a + b == nil)
    }

    @Test("Add returns nil on negative overflow")
    func addNegativeOverflow() {
        let a = Money(Int.min, currency: .gbp)
        let b = Money(-1, currency: .gbp)

        #expect(a + b == nil)
    }

    @Test("Add different currencies returns nil")
    func addDifferentCurrencies() {
        let a = Money(5, currency: .gbp)
        let b = Money(7, currency: .eur)

        #expect(a + b == nil)
    }

    // MARK: - Addition In Place

    @Test("Addition in place succeeds for same currency")
    func additionInPlaceSameCurrency() {
        var a: Money? = Money(5, currency: .gbp)
        let b = Money(7, currency: .gbp)

        a += b

        #expect(a == Money(12, currency: .gbp))
    }

    @Test("Addition in place returns nil for different currency")
    func additionInPlaceDifferentCurrency() {
        var a: Money? = Money(5, currency: .gbp)
        let b = Money(7, currency: .eur)

        a += b

        #expect(a == nil)
    }

    @Test("Addition in place returns nil on positive overflow")
    func additionInPlacePositiveOverflow() {
        var a: Money? = Money(Int.max, currency: .gbp)

        a += Money(1, currency: .gbp)

        #expect(a == nil)
    }

    @Test("Addition in place returns nil on negative overflow")
    func additionInPlaceNegativeOverflow() {
        var a: Money? = Money(Int.min, currency: .gbp)

        a += Money(-1, currency: .gbp)

        #expect(a == nil)
    }

    // MARK: - Subtraction

    @Test("Subtract same currency succeeds")
    func subtractSameCurrency() {
        let a = Money(5, currency: .eur)
        let b = Money(7, currency: .eur)

        #expect(a - b == Money(-2, currency: .eur))
    }

    @Test("Subtracting same currency from optional money succeeds")
    func subtractSameCurrencyFromOptional() {
        let a = Money(9, currency: .gbp)
        let b = Money(5, currency: .gbp)
        let c = Money(3, currency: .gbp)

        #expect((a - b) - c == Money(+1, currency: .gbp))
        #expect(c - (a - b) == Money(-1, currency: .gbp))
    }

    @Test("Subtract returns nil on positive overflow")
    func subtractPositiveOverflow() {
        let a = Money(Int.max, currency: .gbp)
        let b = Money(-1, currency: .gbp)

        #expect(a - b == nil)
    }

    @Test("Subtract returns nil on negative overflow")
    func subtractNegativeOverflow() {
        let a = Money(Int.min, currency: .gbp)
        let b = Money(1, currency: .gbp)

        #expect(a - b == nil)
    }

    @Test("Subtract different currencies returns nil")
    func subtractDifferentCurrencies() {
        let a = Money(5, currency: .gbp)
        let b = Money(7, currency: .eur)

        #expect(a - b == nil)
    }

    // MARK: - Subtraction In Place

    @Test("Subtraction in place succeeds for same currency")
    func subtractionInPlaceSameCurrency() {
        var a: Money? = Money(5, currency: .gbp)
        let b = Money(7, currency: .gbp)

        a -= b

        #expect(a == Money(-2, currency: .gbp))
    }

    @Test("Subtraction in place returns nil for different currency")
    func subtractionInPlaceDifferentCurrency() {
        var a: Money? = Money(5, currency: .gbp)
        let b = Money(7, currency: .eur)

        a -= b

        #expect(a == nil)
    }

    @Test("Subtraction in place returns nil on positive overflow")
    func subtractionInPlacePositiveOverflow() {
        var a: Money? = Money(Int.max, currency: .gbp)

        a -= Money(-1, currency: .gbp)

        #expect(a == nil)
    }

    @Test("Subtraction in place returns nil on negative overflow")
    func subtractionInPlaceNegativeOverflow() {
        var a: Money? = Money(Int.min, currency: .gbp)

        a -= Money(1, currency: .gbp)

        #expect(a == nil)
    }

    // MARK: - Integral Multiplication

    @Test("Integral multiplication succeeds")
    func integralMultiplication() {
        let a = Money(6, currency: .gbp)

        #expect(a * 4 == Money(24, currency: .gbp))
        #expect(4 * a == Money(24, currency: .gbp))
    }

    @Test("Integral multiplication on optional money succeeds")
    func integralMultiplicationOnOptional() {
        let sut: Money? = Money(3, currency: .gbp)

        #expect(sut * 5 == Money(15, currency: .gbp))
        #expect(5 * sut == Money(15, currency: .gbp))
    }

    @Test("Integral multiplication returns correct sign")
    func integralMultiplicationSign() {
        let pos = Money(+12, currency: .gbp) // 12p; £0.12
        let neg = Money(-12, currency: .gbp)

        #expect(pos * 2 == Money(+24, currency: .gbp))
        #expect(neg * 2 == Money(-24, currency: .gbp))

        #expect(pos * -3 == Money(-36, currency: .gbp)) // -36p; -£0.36
        #expect(neg * -3 == Money(+36, currency: .gbp))
    }

    @Test("Integral multiplication traps on positive overflow")
    func integralMultiplicationPositiveOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(Int.max, currency: .gbp) * 2)
        }

        await #expect(processExitsWith: .failure) {
            blackHole(2 * Money(Int.max, currency: .gbp))
        }
    }

    @Test("Integral multiplication traps on negative overflow")
    func integralMultiplicationNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(Int.min, currency: .gbp) * 2)
        }

        await #expect(processExitsWith: .failure) {
            blackHole(2 * Money(Int.min, currency: .gbp))
        }
    }

    // MARK: - Integral Multiplication In Place

    @Test("Integral multiplication in place func succeeds")
    func integralMultiplicationInPlace() {
        var a = Money(2_25, currency: .gbp) // £2.25
        let b: Int = 3

        a *= b

        #expect(a == Money(6_75, currency: .gbp)) // £6.75
    }

    // MARK: - Fractional Multiplication

    #warning("TODO: cover scaled(by: Ratio) once it exists — exact and inexact results, and that the remainder is never lost.")

    // MARK: - Split

    // The algorithm itself is covered by SplitTests. These two check the step that
    // is unique to Money: re-attaching the currency to every share.

    @Test("Split evenly, shares keep the currency")
    func splitEvenlyKeepsCurrency() {
        let sut = Money(2, currency: .gbp)

        let result = sut.split(into: 2)

        #expect(Array(result.amounts) == [Money(1, currency: .gbp), Money(1, currency: .gbp),])
    }

    @Test("Split unevenly, shares keep the currency")
    func splitUnevenlyKeepsCurrency() {
        let sut = Money(3, currency: .gbp)

        let result = sut.split(into: 2)

        #expect(Array(result.amounts) == [Money(2, currency: .gbp), Money(1, currency: .gbp),])
    }
}
