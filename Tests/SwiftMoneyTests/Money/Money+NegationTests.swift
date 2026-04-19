import SwiftMoney
import Testing

@Suite("Negation")
struct NegationTests {

    // MARK: - Negation with `negate()`

    @Test("Negating positive with `negate()`")
    func negatePositive() {
        var value: Money<TST> = 425
        value.negate()
        #expect(value == -425)
    }

    @Test("Negating negative with `negate()`")
    func negateNegative() {
        var value: Money<TST> = -201
        value.negate()
        #expect(value == 201)
    }

    @Test("Negating NaN traps with `negate()`")
    func negateNaN() async {
        await #expect(processExitsWith: .failure) {
            var nan = Money<TST>.nan
            nan.negate()
        }
    }

    @Test("Negating zero with `negate()`")
    func negateZero() {
        var zero = Money<TST>.zero
        zero.negate()
        #expect(zero == .zero)
    }

    @Test("Negative of min with `negate()`")
    func negativeOfMin() {
        var min = Money<TST>.min
        min.negate()
        #expect(min == .max)
    }

    // MARK: - Negation with `-` prefix operator

    @Test("Negating positive with `negate()`")
    func negatePositiveWithPrefixOperator() {
        let pos: Money<TST> = 425
        #expect(-pos == -425)
    }

    @Test("Negating negative with `negate()`")
    func negateNegativeWithPrefixOperator() {
        let neg: Money<TST> = -201
        #expect(-neg == 201)
    }

    @Test("Negating NaN traps with `negate()`")
    func negateNaNWithPrefixOperator() async {
        await #expect(processExitsWith: .failure) { _ = -Money<TST>.nan }
    }

    @Test("Negating zero with `negate()`")
    func negateZeroWithPrefixOperator() {
        #expect(-Money<TST>.zero == .zero)
    }

    @Test("Negative of min with `negate()`")
    func negativeOfMinWithPrefixOperator() {
        #expect(-Money<TST>.min == .max)
    }
}
