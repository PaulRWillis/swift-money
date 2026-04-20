import Foundation
import SwiftMoney
import Testing

@Suite("Decimal Conversions")
struct DecimalTests {
    // Decimal
    //  340282366920938463463374607431768211455
    // -340282366920938463463374607431768211455

    // Int128
    //  170141183460469231731687303715884105727
    // -170141183460469231731687303715884105728

    // MARK: - decimalValue

    @Test("decimalValue returns Decimal.nan for Money.nan")
    func decimalValueForNaN() {
        let moneyNaN = Money<TST>.nan
        #expect(moneyNaN.decimalValue == .nan)
    }

    @Test("decimalValue returns correct Decimal for Money")
    func decimalValue() {
        let value = Money<TST>(minorUnits: 42)
        #expect(value.decimalValue == Decimal(0.42))
    }

    // MARK: - Money init from Decimal

    @Test("Money init from Decimal with exact precision currency allows")
    func decimalInitWithExactPrecision() async {
        await #expect(processExitsWith: .success) {
            let decimal = Decimal(1.23) // valid money represenation in TST currency
            let value = Money<TST>(decimal)
            #expect(value.minorUnits == 123)
        }
    }

    @Test("Money init from Decimal traps on greater precision than currency allows")
    func decimalInitWithGreaterPrecision() async {
        await #expect(processExitsWith: .failure) {
            let decimal = Decimal(1.234) // invalid money representation in TST currency
            _ = Money<TST>(decimal)
        }
    }

    @Test("Money init from Decimal with less precision than currency allows")
    func decimalInitWithLessPrecision() async {
        await #expect(processExitsWith: .success) {
            let decimal = Decimal(1.2)
            let value = Money<TST>(decimal)
            #expect(value.minorUnits == 120)
        }

        await #expect(processExitsWith: .success) {
            let decimal = Decimal(1)
            let value = Money<TST>(decimal)
            #expect(value.minorUnits == 100)
        }
    }

    @Test("Money init from Decimal with NaN")
    func decimalInitWithNaN() {
        let decimalNaN = Decimal.nan
        let value = Money<GBP>(decimalNaN)
        #expect(value == .nan)
    }

    @Test("Money init from Decimal traps on scaled NaN")
    func decimalInitWithScaledNaN() async {
        await #expect(processExitsWith: .failure) {
            let decimal = Decimal(-92233720368547758.08) // 1/100 of Int.min
            _ = Money<TST>(decimal)
        }
    }

    @Test("Money init from Decimal traps on overflow")
    func decimalInitTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            let decimal = Decimal.greatestFiniteMagnitude
            _ = Money<TST>(decimal)
        }
    }

    @Test("Money init from Decimal traps on underflow")
    func decimalInitTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            let decimal = Decimal.leastFiniteMagnitude
            _ = Money<TST>(decimal)
        }
    }

    @Test("Money init from Decimal with zero")
    func decimalInitWithZero() {
        let decimal = Decimal.zero
        let value = Money<TST>(decimal)
        #expect(value == .zero)
    }

    @Test("Money init from Decimal with 0 scaleFactor")
    func decimalInitWithZeroScaleFactor() async {
        await #expect(processExitsWith: .failure) {
            // TST_0 currency gives scale factor of 0 - see `Money.scaleFactor`
            let decimal = Decimal(42)
            _ = Money<TST_0>(decimal)
        }
    }

//    // MARK: - Decimal convenience init
//
//    @Test("Decimal convenience initializer")
//    func decimalConvenienceInit() {
//        let fixed: Money<TST> = 12345
//        let decimal = Decimal(exactly: fixed)
//        #expect(decimal == Decimal(string: "123.45"))
//    }
//
//    @Test("Decimal NaN handling")
//    func decimalNaN() {
//        let nan = FixedPointDecimal.nan
//        #expect(Decimal(nan).isNaN)
//
//        let d = Decimal.nan
//        let fixed = FixedPointDecimal(d)
//        #expect(fixed.isNaN)
//    }
//
//    @Test("Decimal rounding beyond 8 digits")
//    func decimalTruncation() {
//        let decimal = Decimal(string: "123.123456789")!
//        let fixed = FixedPointDecimal(decimal)
//        // 9th digit is 9 > 5, rounds up to 123.12345679
//        #expect(fixed == 123.12345679 as FixedPointDecimal)
//    }
//
//    @Test("Decimal exact initializer — overflow returns nil")
//    func decimalExactOverflow() {
//        let huge = Decimal(string: "999999999999")!  // > 92 billion
//        let result = FixedPointDecimal(exactly: huge)
//        #expect(result == nil)
//    }







//    @Test("Decimal value round trips")
//    func decimalValue() {
//        let decimal = Decimal(12399)
//        let value = Money<TST>(decimal)
//        #expect(Int(value) == 12399)
//    }
//
//    @Test("Decimal traps on NaN")
//    func decimalTrapsOnNaN() async {
//        await #expect(processExitsWith: .failure) { _ = Int(Money<TST>.nan) }
//    }
//
//    @Test("Decimal min round trips")
//    func decimalMin() {
//        let intNearMin = Int.min + 1
//        let value = Money<TST>(minorUnits: intNearMin)
//        #expect(Int(value) == intNearMin)
//    }
//
//    @Test("Decimal max round trips")
//    func decimalMax() {
//        let intMax = Int.max
//        let value = Money<TST>(minorUnits: intMax)
//        #expect(Int(value) == intMax)
//    }
//
//    // MARK: - Exact Int conversions
//
//    @Test("Decimal exact conversion succeeds for Money within Decimal bounds")
//    func exactInitForDecimal() {
//        let int = Int(12399)
//        let value = Money<TST>(minorUnits: int)
//        #expect(Int(exactly: value) == 12399)
//    }
//
//    @Test("Decimal exact conversion traps on NaN")
//    func exactInitForDecimalNaN() {
//        let value = Money<TST>.nan
//        #expect(Int(exactly: value) == nil)
//    }
//
//    @Test("Decimal exact conversion succeeds for Money of Decimal.min value")
//    func exactInitForDecimalMin() {
//        let intNearMin = Int.min + 1
//        let value = Money<TST>(minorUnits: intNearMin)
//        #expect(Int(exactly: value) == intNearMin)
//    }
//
//    @Test("Decimal exact conversion succeeds for Money of Decimal.max value")
//    func exactInitForDecimalMax() {
//        let intMax = Int.max
//        let value = Money<TST>(minorUnits: intMax)
//        #expect(Int(value) == intMax)
//    }
}
