import SwiftMoney
import Testing

@Suite("Sign Tests")
struct SignTests {

    @Test("Sign of an Int128 follows its side of zero")
    func signOfInt128() {
        #expect(Sign(of: Int128(5)) == .positive)
        #expect(Sign(of: Int128(-5)) == .negative)
        #expect(Sign(of: Int128(0)) == .positive)
    }

    @Test("An Int128 rebuilds from its magnitude and sign")
    func rebuildsInt128() {
        #expect(Int128(magnitude: 5, sign: .positive) == 5)
        #expect(Int128(magnitude: 5, sign: .negative) == -5)
        #expect(Int128(magnitude: 0, sign: .negative) == 0)
    }

    @Test("The smallest Int128 comes from its magnitude, not negation")
    func rebuildsMinimum() {
        #expect(Int128(magnitude: Int128.min.magnitude, sign: .negative) == Int128.min)
    }

    @Test("A magnitude with no positive counterpart returns nil")
    func noPositiveCounterpartIsNil() {
        #expect(Int128(magnitude: Int128.min.magnitude, sign: .positive) == nil)
    }
}
