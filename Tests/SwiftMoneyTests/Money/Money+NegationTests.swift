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

    @Test("Negating .min with `negate()` succeeds (MinorUnit excludes Int64.min)")
    func negativeOfMin() {
        var min = Money<TST_100>.min
        min.negate()
        #expect(min == Money<TST_100>.max)
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

    @Test("Negating .min with prefix `-` succeeds (MinorUnit excludes Int64.min)")
    func negativeOfMinWithPrefixOperator() {
        #expect(-Money<TST_100>.min == Money<TST_100>.max)
    }
}
