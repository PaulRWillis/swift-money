import POCMoney
import Testing

@Suite("Money Tests")
struct MoneyTests {

    // MARK: - Addition

    @Test("Add same currency succeeds")
    func addSameCurrency() {
        let a = Money(5, currency: "EUR")
        let b = Money(7, currency: "EUR")

        #expect(a + b == Money(12, currency: "EUR"))
    }

    @Test("Adding same currency to optional money succeeds")
    func addSameCurrencyToOptional() {
        let a = Money(3, currency: "GBP")
        let b = Money(2, currency: "GBP")
        let c = Money(6, currency: "GBP")

        #expect((a + b) + c == Money(11, currency: "GBP"))
        #expect(c + (a + b) == Money(11, currency: "GBP"))
    }

    @Test("Add returns nil on positive overflow")
    func addPositiveOverflow() {
        let a = Money(Int.max, currency: "GBP")
        let b = Money(1, currency: "GBP")

        #expect(a + b == nil)
    }

    @Test("Add returns nil on negative overflow")
    func addNegativeOverflow() {
        let a = Money(Int.min, currency: "GBP")
        let b = Money(-1, currency: "GBP")

        #expect(a + b == nil)
    }

    @Test("Add different currencies returns nil")
    func addDifferentCurrencies() {
        let a = Money(5, currency: "GBP")
        let b = Money(7, currency: "EUR")

        #expect(a + b == nil)
    }

    // MARK: - Addition In Place

    @Test("Addition in place succeeds for same currency")
    func additionInPlaceSameCurrency() {
        var a: Money? = Money(5, currency: "GBP")
        let b = Money(7, currency: "GBP")

        a += b

        #expect(a == Money(12, currency: "GBP"))
    }

    @Test("Addition in place returns nil for different currency")
    func additionInPlaceDifferentCurrency() {
        var a: Money? = Money(5, currency: "GBP")
        let b = Money(7, currency: "EUR")

        a += b

        #expect(a == nil)
    }

    @Test("Addition in place returns nil on positive overflow")
    func additionInPlacePositiveOverflow() {
        var a: Money? = Money(Int.max, currency: "GBP")

        a += Money(1, currency: "GBP")

        #expect(a == nil)
    }

    @Test("Addition in place returns nil on negative overflow")
    func additionInPlaceNegativeOverflow() {
        var a: Money? = Money(Int.min, currency: "GBP")

        a += Money(-1, currency: "GBP")

        #expect(a == nil)
    }

    // MARK: - Subtraction

    @Test("Subtract same currency succeeds")
    func subtractSameCurrency() {
        let a = Money(5, currency: "EUR")
        let b = Money(7, currency: "EUR")

        #expect(a - b == Money(-2, currency: "EUR"))
    }

    @Test("Subtracting same currency from optional money succeeds")
    func subtractSameCurrencyFromOptional() {
        let a = Money(9, currency: "GBP")
        let b = Money(5, currency: "GBP")
        let c = Money(3, currency: "GBP")

        #expect((a - b) - c == Money(+1, currency: "GBP"))
        #expect(c - (a - b) == Money(-1, currency: "GBP"))
    }

    @Test("Subtract returns nil on positive overflow")
    func subtractPositiveOverflow() {
        let a = Money(Int.max, currency: "GBP")
        let b = Money(-1, currency: "GBP")

        #expect(a - b == nil)
    }

    @Test("Subtract returns nil on negative overflow")
    func subtractNegativeOverflow() {
        let a = Money(Int.min, currency: "GBP")
        let b = Money(1, currency: "GBP")

        #expect(a - b == nil)
    }

    @Test("Subtract different currencies returns nil")
    func subtractDifferentCurrencies() {
        let a = Money(5, currency: "GBP")
        let b = Money(7, currency: "EUR")

        #expect(a - b == nil)
    }

    // MARK: - Subtraction In Place

    @Test("Subtraction in place succeeds for same currency")
    func subtractionInPlaceSameCurrency() {
        var a: Money? = Money(5, currency: "GBP")
        let b = Money(7, currency: "GBP")

        a -= b

        #expect(a == Money(-2, currency: "GBP"))
    }

    @Test("Subtraction in place returns nil for different currency")
    func subtractionInPlaceDifferentCurrency() {
        var a: Money? = Money(5, currency: "GBP")
        let b = Money(7, currency: "EUR")

        a -= b

        #expect(a == nil)
    }

    @Test("Subtraction in place returns nil on positive overflow")
    func subtractionInPlacePositiveOverflow() {
        var a: Money? = Money(Int.max, currency: "GBP")

        a -= Money(-1, currency: "GBP")

        #expect(a == nil)
    }

    @Test("Subtraction in place returns nil on negative overflow")
    func subtractionInPlaceNegativeOverflow() {
        var a: Money? = Money(Int.min, currency: "GBP")

        a -= Money(1, currency: "GBP")

        #expect(a == nil)
    }

    // MARK: - Integral Multiplication

    @Test("Integral multiplication succeeds")
    func integralMultiplication() {
        let a = Money(6, currency: "GBP")

        #expect(a * 4 == Money(24, currency: "GBP"))
        #expect(4 * a == Money(24, currency: "GBP"))
    }

    @Test("Integral multiplication on optional money succeeds")
    func integralMultiplicationOnOptional() {
        let sut: Money? = Money(3, currency: "GBP")

        #expect(sut * 5 == Money(15, currency: "GBP"))
        #expect(5 * sut == Money(15, currency: "GBP"))
    }

    @Test("Integral multiplication returns correct sign")
    func integralMultiplicationSign() {
        let pos = Money(+12, currency: "GBP") // 12p; £0.12
        let neg = Money(-12, currency: "GBP")

        #expect(pos * 2 == Money(+24, currency: "GBP"))
        #expect(neg * 2 == Money(-24, currency: "GBP"))

        #expect(pos * -3 == Money(-36, currency: "GBP")) // -36p; -£0.36
        #expect(neg * -3 == Money(+36, currency: "GBP"))
    }

    @Test("Integral multiplication traps on positive overflow")
    func integralMultiplicationPositiveOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = Money(Int.max, currency: "GBP") * 2
        }

        await #expect(processExitsWith: .failure) {
            _ = 2 * Money(Int.max, currency: "GBP")
        }
    }

    @Test("Integral multiplication traps on negative overflow")
    func integralMultiplicationNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            _ = Money(Int.min, currency: "GBP") * 2
        }

        await #expect(processExitsWith: .failure) {
            _ = 2 * Money(Int.min, currency: "GBP")
        }
    }

    // MARK: - Integral Multiplication In Place

    @Test("Integral multiplication in place func succeeds")
    func integralMultiplicationInPlace() {
        var a = Money(2_25, currency: "GBP") // £2.25
        let b: Int = 3

        a *= b

        #expect(a == Money(6_75, currency: "GBP")) // £6.75
    }

    @Test("Integral multiplication in place traps on positive overflow")
    func integralMultiplicationInPlacePositiveOverflow() async {
        await #expect(processExitsWith: .failure) {
            var pos = Money(Int.max, currency: "GBP")
            pos *= 2
        }

        await #expect(processExitsWith: .failure) {
            var neg = Money(Int.min, currency: "GBP")
            neg *= -2
        }
    }

    @Test("Integral multiplication in place traps on negative overflow")
    func integralMultiplicationInPlaceNegativeOverflow() async {
        await #expect(processExitsWith: .failure) {
            var pos = Money(Int.max, currency: "GBP")
            pos *= -2
        }

        await #expect(processExitsWith: .failure) {
            var neg = Money(Int.min, currency: "GBP")
            neg *= 2
        }
    }

    // MARK: - Fractional Multiplication

    #warning("TODO")
}

// TODO: Round out maths functions on `MoneyOf` and `Money`: fractional multiplication and distributions
