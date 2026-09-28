import SwiftMoneyCore
import Testing

@Suite("Int128.DecimalExponent Tests")
struct Int128DecimalExponentTests {

    @Test("An exponent from zero to thirty-eight is accepted", arguments: [0, 38])
    func acceptsTheRange(_ exponent: Int) {
        #expect(Int128.DecimalExponent(exactly: exponent) != nil)
    }

    @Test("An exponent outside zero to thirty-eight is rejected", arguments: [-1, 39])
    func rejectsOutsideTheRange(_ exponent: Int) {
        #expect(Int128.DecimalExponent(exactly: exponent) == nil)
    }
}
