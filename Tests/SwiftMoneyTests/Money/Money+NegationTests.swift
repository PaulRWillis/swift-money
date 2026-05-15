import SwiftMoney
import Testing

@Suite("Money - Negation")
struct Money_NegationTests {

    // MARK: - Negation with `negate()`

    @Test("Negating positive with `negate()`")
    func negatePositive() {
        var value = Money<TST_100>(minorUnits: 425)
        value.negate()
        #expect(value == Money<TST_100>(minorUnits: -425))
    }

    @Test("Negating negative with `negate()`")
    func negateNegative() {
        var value = Money<TST_100>(minorUnits: -201)
        value.negate()
        #expect(value == Money<TST_100>(minorUnits: 201))
    }

    @Test("Negating zero with `negate()`")
    func negateZero() {
        var zero = Money<TST_100>.zero
        zero.negate()
        #expect(zero == .zero)
    }

    @Test("Negating min with `negate()` traps (Int64 overflow)")
    func negativeOfMin() async {
        await #expect(processExitsWith: .failure) {
            var min = Money<TST_100>.min
            min.negate()
        }
    }

    // MARK: - Negation with `-` prefix operator

    @Test("Negating positive with `negate()`")
    func negatePositiveWithPrefixOperator() {
        let pos = Money<TST_100>(minorUnits: 425)
        #expect(-pos == Money<TST_100>(minorUnits: -425))
    }

    @Test("Negating negative with `negate()`")
    func negateNegativeWithPrefixOperator() {
        let neg = Money<TST_100>(minorUnits: -201)
        #expect(-neg == Money<TST_100>(minorUnits: 201))
    }

    @Test("Negating zero with `negate()`")
    func negateZeroWithPrefixOperator() {
        #expect(-Money<TST_100>.zero == .zero)
    }

    @Test("Negating min with prefix `-` traps (Int64 overflow)")
    func negativeOfMinWithPrefixOperator() async {
        await #expect(processExitsWith: .failure) {
            _ = -Money<TST_100>.min
        }
    }
}
