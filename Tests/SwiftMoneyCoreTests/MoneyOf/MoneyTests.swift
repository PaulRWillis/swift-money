import SwiftMoneyCore
import Testing

@Suite("Money Tests")
struct MoneyTests {

    @Test("when constructed exactly from representable value should hold same amount")
    func whenConstructedExactlyFromRepresentableValue_shouldHoldSameAmount() {
        let sut = Money(exactly: Int128(4_99), currency: .gbp)

        #expect(sut == Money(minorUnits: 4_99, currency: .gbp))
    }

    @Test("when constructed exactly from value beyond storage should return nil")
    func whenConstructedExactlyFromValueBeyondStorage_shouldReturnNil() {
        #expect(Money(exactly: Int128.max, currency: .gbp) == nil)
    }

    @Test("when constructed from value beyond storage should trap")
    func whenConstructedFromValueBeyondStorage_shouldTrap() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: Int128.max, currency: .gbp))
        }
    }

    @Test("Add same currency succeeds")
    func addSameCurrency() throws {
        let a = Money(minorUnits: 5, currency: .eur)
        let b = Money(minorUnits: 7, currency: .eur)

        #expect(try a + b == Money(minorUnits: 12, currency: .eur))
    }

    @Test("Add traps on overflow")
    func addTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            let a = Money(minorUnits: Int64.max, currency: .gbp)
            let b = Money(minorUnits: 1, currency: .gbp)

            blackHole(try a + b)
        }
    }

    @Test("Add traps on underflow")
    func addTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            let a = Money(minorUnits: Int64.min, currency: .gbp)
            let b = Money(minorUnits: -1, currency: .gbp)

            blackHole(try a + b)
        }
    }

    @Test("Add different currencies throws, naming both")
    func addDifferentCurrencies() {
        let a = Money(minorUnits: 5, currency: .gbp)
        let b = Money(minorUnits: 7, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a + b
        }
    }

    @Test("Addition in place succeeds for same currency")
    func additionInPlaceSameCurrency() throws {
        var a = Money(minorUnits: 5, currency: .gbp)
        let b = Money(minorUnits: 7, currency: .gbp)

        try a += b

        #expect(a == Money(minorUnits: 12, currency: .gbp))
    }

    @Test("Addition in place throws for different currency, leaving the value untouched")
    func additionInPlaceDifferentCurrency() {
        var a = Money(minorUnits: 5, currency: .gbp)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a += Money(minorUnits: 7, currency: .eur)
        }

        #expect(a == Money(minorUnits: 5, currency: .gbp))
    }

    @Test("Addition in place traps on overflow")
    func additionInPlaceTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            var a = Money(minorUnits: Int64.max, currency: .gbp)
            try a += Money(minorUnits: 1, currency: .gbp)

            blackHole(a)
        }
    }

    @Test("Subtract same currency succeeds")
    func subtractSameCurrency() throws {
        let a = Money(minorUnits: 5, currency: .eur)
        let b = Money(minorUnits: 7, currency: .eur)

        #expect(try a - b == Money(minorUnits: -2, currency: .eur))
    }

    @Test("Subtract traps on overflow")
    func subtractTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            let a = Money(minorUnits: Int64.max, currency: .gbp)
            let b = Money(minorUnits: -1, currency: .gbp)

            blackHole(try a - b)
        }
    }

    @Test("Subtract traps on underflow")
    func subtractTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            let a = Money(minorUnits: Int64.min, currency: .gbp)
            let b = Money(minorUnits: 1, currency: .gbp)

            blackHole(try a - b)
        }
    }

    @Test("Subtract different currencies throws, naming both")
    func subtractDifferentCurrencies() {
        let a = Money(minorUnits: 5, currency: .gbp)
        let b = Money(minorUnits: 7, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a - b
        }
    }

    @Test("Subtraction in place succeeds for same currency")
    func subtractionInPlaceSameCurrency() throws {
        var a = Money(minorUnits: 5, currency: .gbp)
        let b = Money(minorUnits: 7, currency: .gbp)

        try a -= b

        #expect(a == Money(minorUnits: -2, currency: .gbp))
    }

    @Test("Subtraction in place throws for different currency, leaving the value untouched")
    func subtractionInPlaceDifferentCurrency() {
        var a = Money(minorUnits: 5, currency: .gbp)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a -= Money(minorUnits: 7, currency: .eur)
        }

        #expect(a == Money(minorUnits: 5, currency: .gbp))
    }

    @Test("Subtraction in place traps on underflow")
    func subtractionInPlaceTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            var a = Money(minorUnits: Int64.min, currency: .gbp)
            try a -= Money(minorUnits: 1, currency: .gbp)

            blackHole(a)
        }
    }

    @Test("Negation keeps the currency and cannot throw")
    func negationKeepsCurrency() {
        let sut = Money(minorUnits: 4_99, currency: .gbp)

        let negated = -sut

        #expect(negated == Money(minorUnits: -4_99, currency: .gbp))
        #expect(negated.currency == .gbp)
    }

    @Test("Negation traps on the smallest amount")
    func negationTrapsOnSmallestAmount() async {
        await #expect(processExitsWith: .failure) {
            blackHole(-Money(minorUnits: Int64.min, currency: .gbp))
        }
    }

    @Test("Magnitude keeps the currency")
    func magnitudeKeepsCurrency() {
        let sut = Money(minorUnits: -4_99, currency: .gbp)

        let magnitude = sut.magnitude

        #expect(magnitude == Money(minorUnits: 4_99, currency: .gbp))
        #expect(magnitude.currency == .gbp)
    }

    @Test("Magnitude traps on the smallest amount")
    func magnitudeTrapsOnSmallestAmount() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: Int64.min, currency: .gbp).magnitude)
        }
    }

    @Test("Is negative reports the sign")
    func isNegativeReportsSign() {
        #expect(Money(minorUnits: -1, currency: .gbp).isNegative)
        #expect(!Money(minorUnits: 0, currency: .gbp).isNegative)
        #expect(!Money(minorUnits: 1, currency: .gbp).isNegative)
    }

    @Test("Integral multiplication succeeds")
    func integralMultiplication() throws {
        let a = Money(minorUnits: 6, currency: .gbp)

        #expect(a * 4 == Money(minorUnits: 24, currency: .gbp))
        #expect(4 * a == Money(minorUnits: 24, currency: .gbp))
    }

    @Test("Integral multiplication returns correct sign")
    func integralMultiplicationSign() throws {
        let pos = Money(minorUnits: +12, currency: .gbp) // 12p; £0.12
        let neg = Money(minorUnits: -12, currency: .gbp)

        #expect(pos * 2 == Money(minorUnits: +24, currency: .gbp))
        #expect(neg * 2 == Money(minorUnits: -24, currency: .gbp))

        #expect(pos * -3 == Money(minorUnits: -36, currency: .gbp)) // -36p; -£0.36
        #expect(neg * -3 == Money(minorUnits: +36, currency: .gbp))
    }

    @Test("Integral multiplication traps on overflow")
    func integralMultiplicationTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: Int64.max, currency: .gbp) * 2)
        }

        await #expect(processExitsWith: .failure) {
            blackHole(2 * Money(minorUnits: Int64.max, currency: .gbp))
        }
    }

    @Test("Integral multiplication traps on underflow")
    func integralMultiplicationTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: Int64.min, currency: .gbp) * 2)
        }

        await #expect(processExitsWith: .failure) {
            blackHole(2 * Money(minorUnits: Int64.min, currency: .gbp))
        }
    }

    @Test("Integral multiplication in place succeeds")
    func integralMultiplicationInPlace() throws {
        var a = Money(minorUnits: 2_25, currency: .gbp) // £2.25
        let b: Int = 3

        a *= b

        #expect(a == Money(minorUnits: 6_75, currency: .gbp)) // £6.75
    }

    @Test("One try covers a whole chain")
    func oneTryCoversAWholeChain() throws {
        let result = try (Money(minorUnits: 10_00, currency: .gbp) * 3)
            + Money(minorUnits: 2_50, currency: .gbp)
            - Money(minorUnits: 1_00, currency: .gbp)

        #expect(result == Money(minorUnits: 31_50, currency: .gbp))
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
                }
            }
        }

        let mismatch = describe { () throws(MoneyError) in
            try Money(minorUnits: 1, currency: .gbp) + Money(minorUnits: 1, currency: .eur)
        }
        let fine = describe { () throws(MoneyError) in
            try Money(minorUnits: 1, currency: .gbp) + Money(minorUnits: 1, currency: .gbp)
        }

        #expect(mismatch == "mismatch GBP/EUR")
        #expect(fine == "ok")
    }

    // A caller who wants an Optional still gets one, and gets a single Optional for the whole chain
    // rather than one per step.
    @Test("try? yields one Optional for a whole chain")
    func tryQuestionMarkYieldsOneOptional() {
        let failed: Money? = try? (Money(minorUnits: 10_00, currency: .gbp) * 3) + Money(minorUnits: 1, currency: .eur)
        let succeeded: Money? = try? Money(minorUnits: 10_00, currency: .gbp) + Money(minorUnits: 2_50, currency: .gbp)

        #expect(failed == nil)
        #expect(succeeded == Money(minorUnits: 12_50, currency: .gbp))
    }

    @Test("Is multiple of money where euclidean remainder is zero")
    func isMultipleOnZeroRemainder() throws {
        let a = Money(minorUnits: 3_33, currency: .gbp)
        let b = Money(minorUnits: 9_99, currency: .gbp)

        #expect(try b.isMultiple(of: a))
        #expect(try !a.isMultiple(of: b))
    }

    @Test("Is not a multiple where the euclidean remainder is not zero")
    func isNotMultipleForRemainder() throws {
        let a = Money(minorUnits: 2_00, currency: .gbp) // £2.00
        let b = Money(minorUnits: 6_01, currency: .gbp) // Results in £0.01 remainder

        #expect(try !b.isMultiple(of: a))
    }

    @Test("Zero is a multiple of any value")
    func zeroIsMultipleOfAnyValue() throws {
        let zero = Money(minorUnits: 0, currency: .gbp)

        for value in [Money(minorUnits: 0, currency: .gbp), Money(minorUnits: 10, currency: .gbp), Money(minorUnits: 999_99, currency: .gbp)] {
            #expect(try zero.isMultiple(of: value))
        }
    }

    @Test("No amount other than zero is a multiple of zero")
    func onlyZeroIsMultipleOfZero() throws {
        let zero = Money(minorUnits: 0, currency: .gbp)

        #expect(try zero.isMultiple(of: zero))
        #expect(try !Money(minorUnits: 1, currency: .gbp).isMultiple(of: zero))
    }

    @Test("Testing against a different currency throws, naming both")
    func isMultipleOfDifferentCurrencyThrows() {
        let a = Money(minorUnits: 9_99, currency: .gbp)
        let b = Money(minorUnits: 3_33, currency: .eur)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try a.isMultiple(of: b)
        }
    }

    // The algorithm itself is covered by ApplyingTests, which drives it through GBP. These check the
    // steps unique to Money: re-attaching the currency, and throwing where MoneyOf traps.

    @Test("Scaling keeps the currency")
    func scalingKeepsTheCurrency() {
        let sut = Money(minorUnits: 10_00, currency: .eur)

        #expect(sut.applying("0.2").rounded(.toNearestOrEven) == Money(minorUnits: 2_00, currency: .eur))
    }

    @Test("An inexact result settles and keeps the currency")
    func inexactScalingKeepsTheCurrency() {
        // 10 × 0.25 = 2.5, settled up to 3, in the currency it started in.
        let scaled = Money(minorUnits: 10, currency: .eur).applying("0.25").rounded(.up)

        #expect(scaled == Money(minorUnits: 3, currency: .eur))
    }

    @Test("Settling a scaled amount past the range traps")
    func scalingTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: Int64.max, currency: .gbp).applying("2").rounded(.toNearestOrEven))
        }
    }

    @Test("Settling a scaled amount below the range traps")
    func scalingTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: Int64.min, currency: .gbp).applying("2").rounded(.toNearestOrEven))
        }
    }

    // Three halves of this is exactly the largest amount with a half left over, so truncating fits and
    // only the rounding step passes the maximum.
    @Test("Truncating reaches the largest amount exactly")
    func truncatingReachesTheLargestAmount() throws {
        let sut = Money(minorUnits: Int64.max / 3 * 2 + 1, currency: .gbp)

        #expect(sut.applying("1.5").rounded(.towardZero) == Money(minorUnits: Int64.max, currency: .gbp))
    }

    @Test("Rounding traps on overflow, where truncating would not")
    func roundingTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(
                Money(minorUnits: Int64.max / 3 * 2 + 1, currency: .gbp)
                    .applying("1.5").rounded(.awayFromZero)
            )
        }
    }

    // The algorithm itself is covered by SplitTests. These two check the step that
    // is unique to Money: re-attaching the currency to every share.

    @Test("Split evenly, shares keep the currency")
    func splitEvenlyKeepsCurrency() {
        let sut = Money(minorUnits: 2, currency: .gbp)

        let result = sut.split(into: 2)

        #expect(Array(result.amounts) == [Money(minorUnits: 1, currency: .gbp), Money(minorUnits: 1, currency: .gbp),])
    }

    @Test("Split unevenly, shares keep the currency")
    func splitUnevenlyKeepsCurrency() {
        let sut = Money(minorUnits: 3, currency: .gbp)

        let result = sut.split(into: 2)

        #expect(Array(result.amounts) == [Money(minorUnits: 2, currency: .gbp), Money(minorUnits: 1, currency: .gbp),])
    }

    // The chaining itself is covered by UnroundedTests, which drives it through GBP. These check the
    // steps unique to Money: keeping the currency, and throwing where MoneyOf traps.

    @Test("A chain keeps the currency")
    func chainKeepsTheCurrency() throws {
        let sut = Money(minorUnits: 10_00, currency: .eur)
        let third = try #require(Rate(string: "1/3"))

        let chained = sut.unrounded * third * "3/1"

        #expect(chained.rounded(.toNearestOrEven) == Money(minorUnits: 10_00, currency: .eur))
    }

    // One `try` covers the whole expression, as it does for the rest of Money's arithmetic.
    @Test("A chain of two rates settles once")
    func chainOfTwoRatesSettlesOnce() throws {
        let sut = Money(minorUnits: 10_000_00, currency: .gbp)
        let dayCount = try #require(Rate(string: "31/365"))

        let interest = sut.unrounded * "45/1000" * dayCount

        #expect(interest.rounded(.toNearestOrEven) == Money(minorUnits: 38_22, currency: .gbp))
    }

    @Test("An unrounded Money amount scales, applies, and divides, keeping its currency")
    func unroundedMoneyOperations() throws {
        let sut = Money(minorUnits: 10_00, currency: .eur)
        let third = try #require(Rate(string: "1/3"))

        #expect((third * sut.unrounded).rounded(.toNearestOrEven) == Money(minorUnits: 3_33, currency: .eur))
        #expect((sut.unrounded * 3).rounded(.toNearestOrEven) == Money(minorUnits: 30_00, currency: .eur))
        #expect((3 * sut.unrounded).rounded(.toNearestOrEven) == Money(minorUnits: 30_00, currency: .eur))
        #expect(sut.unrounded.applying(third) == sut.unrounded * third)
        #expect(sut.unrounded.divided(by: 3).rounded(.toNearestOrEven) == Money(minorUnits: 3_33, currency: .eur))

        var scaled = sut.unrounded
        scaled *= third
        #expect(scaled == sut.unrounded * third)

        var byWholeNumber = sut.unrounded
        byWholeNumber *= 3
        #expect(byWholeNumber == sut.unrounded * 3)

        #expect(sut.unrounded.divided(byExactly: 0) == nil)
        let quarter = try #require(sut.unrounded.divided(byExactly: 4))
        #expect(quarter.rounded(.toNearestOrEven) == Money(minorUnits: 2_50, currency: .eur))
    }

    @Test("Scaling an unrounded amount traps on overflow")
    func unroundedScalingTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: Int64.max, currency: .gbp).unrounded * 20)
        }
    }

    @Test("Scaling an unrounded amount traps on underflow")
    func unroundedScalingTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: Int64.min, currency: .gbp).unrounded * 20)
        }
    }

    @Test("Scaling an unrounded amount in place traps on overflow")
    func unroundedScalingInPlaceTraps() async {
        await #expect(processExitsWith: .failure) {
            var unrounded = Money(minorUnits: Int64.max, currency: .gbp).unrounded
            unrounded *= 20

            blackHole(unrounded)
        }
    }

    // Settling cannot overflow, so it needs no `try` even at the largest amount.
    @Test("Settling an unrounded amount never throws")
    func settlingNeverThrows() {
        let sut = Money(minorUnits: Int64.max, currency: .gbp)

        #expect(sut.unrounded.rounded(.awayFromZero) == sut)
    }

    @Test("Adding unrounded amounts keeps the currency")
    func addingUnroundedKeepsTheCurrency() throws {
        let third = try Money(minorUnits: 9_99, currency: .eur).unrounded * #require(Rate(string: "1/3"))

        let whole = try third + third + third

        #expect(whole.rounded(.toNearestOrEven) == Money(minorUnits: 9_99, currency: .eur))
    }

    @Test("Adding unrounded amounts in different currencies throws, naming both")
    func addingUnroundedDifferentCurrenciesThrows() {
        let sterling = Money(minorUnits: 1_00, currency: .gbp).unrounded
        let euros = Money(minorUnits: 1_00, currency: .eur).unrounded

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try sterling + euros
        }
    }

    @Test("A settled amount joins an unrounded chain")
    func settledAmountJoinsAnUnroundedChain() throws {
        let net = try Money(minorUnits: 5_00, currency: .gbp).unrounded * #require(Rate(string: "1/3"))
            + Money(minorUnits: 2_00, currency: .gbp)
            - Money(minorUnits: 1_00, currency: .gbp)

        #expect(net.rounded(.toNearestOrEven) == Money(minorUnits: 2_67, currency: .gbp))
    }

    @Test("A settled amount in another currency throws")
    func settledAmountInAnotherCurrencyThrows() {
        let sterling = Money(minorUnits: 1_00, currency: .gbp).unrounded

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try sterling + Money(minorUnits: 1_00, currency: .eur)
        }
    }

    @Test("Adding unrounded amounts traps on overflow")
    func addingUnroundedTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            let huge = Money(minorUnits: Int64.max, currency: .gbp).unrounded * 15

            blackHole(try huge + huge)
        }
    }

    @Test("Subtracting unrounded amounts traps on underflow")
    func subtractingUnroundedTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            let largest = Money(minorUnits: Int64.max, currency: .gbp).unrounded * 15
            let smallest = Money(minorUnits: Int64.min, currency: .gbp).unrounded * 15

            blackHole(try smallest - largest)
        }
    }

    @Test("Adding to an unrounded amount in place traps on overflow")
    func addingUnroundedInPlaceTraps() async {
        await #expect(processExitsWith: .failure) {
            let huge = Money(minorUnits: Int64.max, currency: .gbp).unrounded * 15
            var running = huge
            try running += huge

            blackHole(running)
        }
    }
}
