import SwiftMoney
import Testing

@Suite("Int128 Power of Ten Tests")
struct Int128PowerOfTenTests {

    @Test("Ten to the zero is one")
    func tenToZero() {
        #expect(Int128.powerOfTen(0) == 1)
    }

    @Test("Ten to the eighteenth is the fixed-point scale")
    func tenToScale() {
        #expect(Int128.powerOfTen(18) == Fixed.scale)
    }

    @Test("Ten to the largest representable exponent fits")
    func tenToLargest() {
        // 10^38 < Int128.max; 10^39 does not.
        #expect(Int128.powerOfTen(38) != nil)
    }

    @Test("An exponent that overflows returns nil")
    func overflowIsNil() {
        #expect(Int128.powerOfTen(39) == nil)
    }

    @Test("A negative exponent returns nil")
    func negativeIsNil() {
        #expect(Int128.powerOfTen(-1) == nil)
    }

    @Test("Each power is ten times the one below", arguments: [1, 2, 5, 10, 18, 30])
    func stepsByTen(_ exponent: Int) throws {
        let power = try #require(Int128.powerOfTen(exponent))
        let previous = try #require(Int128.powerOfTen(exponent - 1))

        #expect(power == previous * 10)
    }
}
