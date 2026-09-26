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
