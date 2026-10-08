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

    @Test("Minus one times two to the 63rd, in any wide type, is the smallest amount")
    func minusOneTimesTwoToThe63InEveryWideType() {
        let typed = GBP(minorUnits: -1)
        let runtime = Money(minorUnits: -1, currency: .gbp)
        let smallest = Money(minorUnits: Int64.min, currency: .gbp)

        #expect(typed * (UInt128(1) << 63) == GBP.min)
        #expect(typed * (Int128(1) << 63) == GBP.min)
        #expect((Int128(1) << 63) * typed == GBP.min)
        #expect(runtime * (UInt128(1) << 63) == smallest)
        #expect(runtime * (Int128(1) << 63) == smallest)
        #expect((UInt64(1) << 63) * runtime == smallest)
    }

    @Test("Zero times any wide multiplier stays zero")
    func zeroTimesEveryWideMultiplier() {
        let typed = GBP(minorUnits: 0)
        let runtime = Money(minorUnits: 0, currency: .gbp)

        #expect(typed * UInt64.max == typed)
        #expect(typed * Int128.min == typed)
        #expect(typed * Int128.max == typed)
        #expect(typed * UInt128.max == typed)
        #expect(runtime * UInt64.max == runtime)
        #expect(runtime * Int128.min == runtime)
        #expect(runtime * UInt128.max == runtime)
    }

    @Test("One times two to the 63rd traps")
    func oneTimesTwoToThe63Traps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: 1) * (UInt64(1) << 63))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: 1, currency: .gbp) * (UInt64(1) << 63))
        }
    }

    @Test("Minus one times one below the smallest Int64 traps")
    func minusOneTimesBelowInt64Traps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: -1) * (Int128(Int64.min) - 1))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: -1, currency: .gbp) * (Int128(Int64.min) - 1))
        }
    }

    @Test("Minus one times two to the 63rd plus one traps")
    func minusOneTimesPastTwoToThe63Traps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: -1) * ((UInt64(1) << 63) + 1))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: -1, currency: .gbp) * ((UInt64(1) << 63) + 1))
        }
    }

    @Test("Minus one times the largest UInt64 traps")
    func minusOneTimesLargestUInt64Traps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: -1) * UInt64.max)
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: -1, currency: .gbp) * UInt64.max)
        }
    }

    @Test("The smallest amount times two to the 63rd traps")
    func smallestTimesTwoToThe63Traps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.min * (UInt64(1) << 63))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: Int64.min, currency: .gbp) * (UInt64(1) << 63))
        }
    }

    @Test("One times one below the smallest Int64 traps")
    func oneTimesBelowInt64Traps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: 1) * (Int128(Int64.min) - 1))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: 1, currency: .gbp) * (Int128(Int64.min) - 1))
        }
    }

    @Test("A multiplier at the 128-bit extremes traps")
    func multiplierAt128BitExtremesTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: -1) * UInt128.max)
        }
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: 1) * Int128.min)
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: -1, currency: .gbp) * UInt128.max)
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: 1, currency: .gbp) * Int128.min)
        }
    }

    @Test("Minus one times the smallest Int64 traps")
    func minusOneTimesSmallestInt64Traps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP(minorUnits: -1) * Int128(Int64.min))
        }
        await #expect(processExitsWith: .failure) {
            blackHole(Money(minorUnits: -1, currency: .gbp) * Int128(Int64.min))
        }
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
