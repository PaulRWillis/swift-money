import SwiftMoneyCore
import Testing

@Suite("MoneyOf multiplication does not trap on a safe answer")
struct MoneyOfArithmeticWidenedMultiplicationTests {

    @Test("Zero times a multiplier wider than Int64 stays zero")
    func zeroTimesUInt64BiggerThanInt64() {
        let zero = GBP(minorUnits: 0)
        let biggerThanInt64Max: UInt64 = UInt64(Int64.max) + 1

        #expect(zero * biggerThanInt64Max == zero)
    }

    @Test("Zero times a multiplier wider than Int128 stays zero")
    func zeroTimesUInt128BiggerThanInt128() {
        let zero = GBP(minorUnits: 0)
        let biggerThanInt128Max: UInt128 = UInt128(Int128.max) + 1

        #expect(zero * biggerThanInt128Max == zero)
    }

    @Test("A narrow multiplier gives the same result as an Int")
    func narrowMultiplierMatchesInt() {
        let price = GBP(minorUnits: 4_99)
        let runtime = Money(minorUnits: 4_99, currency: .gbp)
        var inPlace = price
        inPlace *= UInt8(3)

        #expect(price * Int32(3) == price * 3)
        #expect(price * Int16(-3) == price * -3)
        #expect(UInt8(3) * price == 3 * price)
        #expect(inPlace == price * 3)
        #expect(runtime * Int32(3) == runtime * 3)
        #expect(UInt8(3) * runtime == 3 * runtime)
    }

    // 2^63 does not fit Int64, but -1 × 2^63 is exactly Int64.min, the smallest amount.
    @Test("A multiplier wider than Int64 still gives a representable product")
    func multiplierWiderThanInt64GivesRepresentableProduct() {
        let twoToThe63 = UInt64(Int64.max) + 1

        #expect(GBP(minorUnits: -1) * twoToThe63 == GBP.min)
        #expect(Money(minorUnits: -1, currency: .gbp) * twoToThe63 == Money(minorUnits: Int64.min, currency: .gbp))
    }

    @Test("A plain Int multiplier that truly overflows still traps")
    func intMultiplierStillTrapsOnRealOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: 2) * Int.max)
        }
    }

    @Test("A wide multiplier that truly overflows still traps")
    func wideMultiplierStillTrapsOnRealOverflow() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: 1) * UInt64.max)
        }
    }

    @Test("The reversed operand order (Int × Money) also stays zero, not just Money × Int")
    func reversedOrderZeroTimesWideMultiplierStaysZero() {
        let zero = GBP(minorUnits: 0)
        let biggerThanInt128Max: UInt128 = UInt128(Int128.max) + 1

        #expect(Int.max * zero == zero)
        #expect(biggerThanInt128Max * zero == zero)
    }
}
