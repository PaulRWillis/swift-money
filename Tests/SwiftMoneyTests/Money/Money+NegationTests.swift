import SwiftMoney
import Testing

@Suite("Money - Negation")
struct Money_NegationTests {

    // MARK: - Negation with `negate()`

    @Test("Negating positive with `negate()`")
    func negatePositive() {
        var value: Money<TST_100> = 425
        value.negate()
        #expect(value == -425)
    }

    @Test("Negating negative with `negate()`")
    func negateNegative() {
        var value: Money<TST_100> = -201
        value.negate()
        #expect(value == 201)
    }

    @Test("Negating NaN traps with `negate()`")
    func negateNaN() async {
        await #expect(processExitsWith: .failure) {
            var nan = Money<TST_100>.nan
            nan.negate()
        }
    }

    @Test("Negating zero with `negate()`")
    func negateZero() {
        var zero = Money<TST_100>.zero
        zero.negate()
        #expect(zero == .zero)
    }

    @Test("Negative of min with `negate()`")
    func negativeOfMin() {
        var min = Money<TST_100>.min
        min.negate()
        #expect(min == .max)
    }

    // MARK: - Negation with `-` prefix operator

    @Test("Negating positive with `negate()`")
    func negatePositiveWithPrefixOperator() {
        let pos: Money<TST_100> = 425
        #expect(-pos == -425)
    }

    @Test("Negating negative with `negate()`")
    func negateNegativeWithPrefixOperator() {
        let neg: Money<TST_100> = -201
        #expect(-neg == 201)
    }

    @Test("Negating NaN traps with `negate()`")
    func negateNaNWithPrefixOperator() async {
        await #expect(processExitsWith: .failure) { _ = -Money<TST_100>.nan }
    }

    @Test("Negating zero with `negate()`")
    func negateZeroWithPrefixOperator() {
        #expect(-Money<TST_100>.zero == .zero)
    }

    @Test("Negative of min with `negate()`")
    func negativeOfMinWithPrefixOperator() {
        #expect(-Money<TST_100>.min == .max)
    }
}
