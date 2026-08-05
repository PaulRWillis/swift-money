import POCMoney
import Testing

@Suite("Money Tests")
struct MoneyTests {

    // MARK: - Addition

    @Test("Add same currency succeeds")
    func addSameCurrency() throws {
        let a = Money(5, currency: .eur)
        let b = Money(7, currency: .eur)

        #expect(try a + b == Money(12, currency: .eur))
    }

    @Test("Add throws on positive overflow")
    func addPositiveOverflow() {
        let a = Money(Int.max, currency: .gbp)
        let b = Money(1, currency: .gbp)

        #expect(throws: MoneyError.overflow) {
            try a + b
        }
    }

    @Test("Add throws on negative overflow")
    func addNegativeOverflow() {
        let a = Money(Int.min, currency: .gbp)
        let b = Money(-1, currency: .gbp)

        #expect(throws: MoneyError.overflow) {
            try a + b
        }
    }

    @Test("Add different currencies throws, naming both")
    func addDifferentCurrencies() {
        let a = Money(5, currency: .gbp)
        let b = Money(7, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a + b
        }
    }

    // MARK: - Addition In Place

    @Test("Addition in place succeeds for same currency")
    func additionInPlaceSameCurrency() throws {
        var a = Money(5, currency: .gbp)
        let b = Money(7, currency: .gbp)

        try a += b

        #expect(a == Money(12, currency: .gbp))
    }

    @Test("Addition in place throws for different currency, leaving the value untouched")
    func additionInPlaceDifferentCurrency() {
        var a = Money(5, currency: .gbp)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a += Money(7, currency: .eur)
        }

        #expect(a == Money(5, currency: .gbp))
    }

    @Test("Addition in place throws on overflow")
    func additionInPlaceOverflow() {
        var a = Money(Int.max, currency: .gbp)

        #expect(throws: MoneyError.overflow) {
            try a += Money(1, currency: .gbp)
        }
    }

    // MARK: - Subtraction

    @Test("Subtract same currency succeeds")
    func subtractSameCurrency() throws {
        let a = Money(5, currency: .eur)
        let b = Money(7, currency: .eur)

        #expect(try a - b == Money(-2, currency: .eur))
    }

    @Test("Subtract throws on positive overflow")
    func subtractPositiveOverflow() {
        let a = Money(Int.max, currency: .gbp)
        let b = Money(-1, currency: .gbp)

        #expect(throws: MoneyError.overflow) {
            try a - b
        }
    }

    @Test("Subtract throws on negative overflow")
    func subtractNegativeOverflow() {
        let a = Money(Int.min, currency: .gbp)
        let b = Money(1, currency: .gbp)

        #expect(throws: MoneyError.overflow) {
            try a - b
        }
    }

    @Test("Subtract different currencies throws, naming both")
    func subtractDifferentCurrencies() {
        let a = Money(5, currency: .gbp)
        let b = Money(7, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a - b
        }
    }

    // MARK: - Subtraction In Place

    @Test("Subtraction in place succeeds for same currency")
    func subtractionInPlaceSameCurrency() throws {
        var a = Money(5, currency: .gbp)
        let b = Money(7, currency: .gbp)

        try a -= b

        #expect(a == Money(-2, currency: .gbp))
    }

    @Test("Subtraction in place throws for different currency, leaving the value untouched")
    func subtractionInPlaceDifferentCurrency() {
        var a = Money(5, currency: .gbp)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a -= Money(7, currency: .eur)
        }

        #expect(a == Money(5, currency: .gbp))
    }

    @Test("Subtraction in place throws on overflow")
    func subtractionInPlaceOverflow() {
        var a = Money(Int.min, currency: .gbp)

        #expect(throws: MoneyError.overflow) {
            try a -= Money(1, currency: .gbp)
        }
    }

    // MARK: - Integral Multiplication

    @Test("Integral multiplication succeeds")
    func integralMultiplication() throws {
        let a = Money(6, currency: .gbp)

        #expect(try a * 4 == Money(24, currency: .gbp))
        #expect(try 4 * a == Money(24, currency: .gbp))
    }

    @Test("Integral multiplication returns correct sign")
    func integralMultiplicationSign() throws {
        let pos = Money(+12, currency: .gbp) // 12p; £0.12
        let neg = Money(-12, currency: .gbp)

        #expect(try pos * 2 == Money(+24, currency: .gbp))
        #expect(try neg * 2 == Money(-24, currency: .gbp))

        #expect(try pos * -3 == Money(-36, currency: .gbp)) // -36p; -£0.36
        #expect(try neg * -3 == Money(+36, currency: .gbp))
    }

    @Test("Integral multiplication throws on positive overflow")
    func integralMultiplicationPositiveOverflow() {
        #expect(throws: MoneyError.overflow) {
            try Money(Int.max, currency: .gbp) * 2
        }

        #expect(throws: MoneyError.overflow) {
            try 2 * Money(Int.max, currency: .gbp)
        }
    }

    @Test("Integral multiplication throws on negative overflow")
    func integralMultiplicationNegativeOverflow() {
        #expect(throws: MoneyError.overflow) {
            try Money(Int.min, currency: .gbp) * 2
        }

        #expect(throws: MoneyError.overflow) {
            try 2 * Money(Int.min, currency: .gbp)
        }
    }

    // MARK: - Integral Multiplication In Place

    @Test("Integral multiplication in place succeeds")
    func integralMultiplicationInPlace() throws {
        var a = Money(2_25, currency: .gbp) // £2.25
        let b: Int = 3

        try a *= b

        #expect(a == Money(6_75, currency: .gbp)) // £6.75
    }

    // MARK: - Chaining

    @Test("One try covers a whole chain")
    func oneTryCoversAWholeChain() throws {
        let result = try (Money(10_00, currency: .gbp) * 3)
            + Money(2_50, currency: .gbp)
            - Money(1_00, currency: .gbp)

        #expect(result == Money(31_50, currency: .gbp))
    }

    // A typed throw means the catch is exhaustive over MoneyError without a `default`, so a new case
    // would be a compile error at every call site rather than silently falling through.
    @Test("A catch over MoneyError needs no default clause")
    func catchIsExhaustive() {
        func describe(_ work: () throws(MoneyError) -> Money) -> String {
            do {
                _ = try work()
                return "ok"
            } catch {
                switch error {
                case let .currencyMismatch(lhs, rhs): return "mismatch \(lhs)/\(rhs)"
                case .overflow: return "overflow"
                }
            }
        }

        let mismatch = describe { () throws(MoneyError) in
            try Money(1, currency: .gbp) + Money(1, currency: .eur)
        }
        let overflow = describe { () throws(MoneyError) in
            try Money(.max, currency: .gbp) * 2
        }

        #expect(mismatch == "mismatch GBP/EUR")
        #expect(overflow == "overflow")
    }

    // A caller who wants an Optional still gets one, and gets a single Optional for the whole chain
    // rather than one per step.
    @Test("try? yields one Optional for a whole chain")
    func tryQuestionMarkYieldsOneOptional() {
        let failed: Money? = try? (Money(10_00, currency: .gbp) * 3) + Money(1, currency: .eur)
        let succeeded: Money? = try? Money(10_00, currency: .gbp) + Money(2_50, currency: .gbp)

        #expect(failed == nil)
        #expect(succeeded == Money(12_50, currency: .gbp))
    }

    // MARK: - isMultiple(of:)

    @Test("Is multiple of money where euclidean remainder is zero")
    func isMultipleOnZeroRemainder() throws {
        let a = Money(3_33, currency: .gbp)
        let b = Money(9_99, currency: .gbp)

        #expect(try b.isMultiple(of: a))
        #expect(try !a.isMultiple(of: b))
    }

    @Test("Is not a multiple where the euclidean remainder is not zero")
    func isNotMultipleForRemainder() throws {
        let a = Money(2_00, currency: .gbp) // £2.00
        let b = Money(6_01, currency: .gbp) // Results in £0.01 remainder

        #expect(try !b.isMultiple(of: a))
    }

    @Test("Zero is a multiple of any value")
    func zeroIsMultipleOfAnyValue() throws {
        let zero = Money(0, currency: .gbp)

        for value in [Money(0, currency: .gbp), Money(10, currency: .gbp), Money(999_99, currency: .gbp)] {
            #expect(try zero.isMultiple(of: value))
        }
    }

    @Test("No amount other than zero is a multiple of zero")
    func onlyZeroIsMultipleOfZero() throws {
        let zero = Money(0, currency: .gbp)

        #expect(try zero.isMultiple(of: zero))
        #expect(try !Money(1, currency: .gbp).isMultiple(of: zero))
    }

    @Test("Testing against a different currency throws, naming both")
    func isMultipleOfDifferentCurrencyThrows() {
        let a = Money(9_99, currency: .gbp)
        let b = Money(3_33, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a.isMultiple(of: b)
        }
    }

    // MARK: - Fractional Scaling

    // The algorithm itself is covered by ScalingTests, which drives it through GBP. These check the
    // steps unique to Money: re-attaching the currency, and throwing where MoneyOf traps.

    @Test("Scaling keeps the currency")
    func scalingKeepsTheCurrency() throws {
        let sut = Money(9_99, currency: .eur)

        #expect(try sut.scaled(by: Ratio(1, 3)) == .exact(Money(3_33, currency: .eur)))
        #expect(try sut.scaled(by: Ratio(1, 3), rounding: .toNearestOrEven) == Money(3_33, currency: .eur))
    }

    @Test("An inexact result keeps the currency")
    func inexactScalingKeepsTheCurrency() throws {
        let scaled = try Money(10_00, currency: .eur).scaled(by: Ratio(1, 3))

        guard case let .inexact(amount, remainder) = scaled else {
            Issue.record("Expected an inexact result")
            return
        }

        #expect(amount == Money(3_33, currency: .eur))
        #expect(Ratio(remainder) == Ratio(1, 3))
    }

    @Test("Scaling past the largest amount throws, where MoneyOf traps")
    func scalingPastTheLargestAmountThrows() {
        let sut = Money(.max, currency: .gbp)

        #expect(throws: MoneyError.overflow) {
            try sut.scaled(by: Ratio(2, 1))
        }

        #expect(throws: MoneyError.overflow) {
            try sut.scaled(by: Ratio(2, 1), rounding: .towardZero)
        }
    }

    // Three halves of this is exactly the largest amount with a half left over, so truncating fits and
    // only the rounding step passes the maximum.
    @Test("Rounding past the largest amount throws, where truncating would not")
    func roundingPastTheLargestAmountThrows() throws {
        let sut = Money(Int.max / 3 * 2 + 1, currency: .gbp)

        #expect(try sut.scaled(by: Ratio(3, 2), rounding: .towardZero) == Money(.max, currency: .gbp))

        #expect(throws: MoneyError.overflow) {
            try sut.scaled(by: Ratio(3, 2), rounding: .awayFromZero)
        }
    }

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
