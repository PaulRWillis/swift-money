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
        #expect(value.isNaN)
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

    @Test("Money init from Decimal with literal value")
    func decimalInitWithLiteralValue() {
        let value = Money<GBP>(99.95)
        #expect(value.decimalValue == Decimal(99.95))
    }

    // MARK: - Money init from exact Decimal

    @Test("Money init from exact Decimal with exact precision currency allows")
    func decimalExactInitWithExactPrecision() throws {
        let decimal = Decimal(1.23) // valid money represenation in TST currency
        let value = try #require(Money<TST>(exactly: decimal))
        #expect(value.minorUnits == 123)
    }

    @Test("Money init from exact Decimal returns nil on greater precision than currency allows")
    func decimalExactInitWithGreaterPrecision() {
        let decimal = Decimal(1.234) // invalid money representation in TST currency
        #expect(Money<TST>(exactly: decimal) == nil)
    }

    @Test("Money init from exact Decimal with less precision than currency allows")
    func decimalExactInitWithLessPrecision() throws {
        let decimal = Decimal(1)
        let value = try #require(Money<TST>(exactly: decimal))
        #expect(value.minorUnits == 100)
    }

    @Test("Money init from exact Decimal returns nil on NaN")
    func decimalExactInitWithNaN() throws {
        let decimalNaN = Decimal.nan
        let value = try #require(Money<GBP>(exactly: decimalNaN))
        #expect(value.isNaN)
    }

    @Test("Money init from exact Decimal returns nil on scaled NaN")
    func decimalExactInitWithScaledNaN() {
        let decimal = Decimal(-92233720368547758.08) // 1/100 of Int.min
        #expect(Money<TST>(exactly: decimal) == nil)
    }

    @Test("Money init from exact Decimal returns nil on overflow")
    func decimalExactInitTrapsOnOverflow() {
        let decimal = Decimal.greatestFiniteMagnitude
        #expect(Money<TST>(exactly: decimal) == nil)
    }

    @Test("Money init from exact Decimal returns nil on underflow")
    func decimalExactInitTrapsOnUnderflow() {
        let decimal = Decimal.leastFiniteMagnitude
        #expect(Money<TST>(exactly: decimal) == nil)
    }

    @Test("Money init from exact Decimal with zero")
    func decimalExactInitWithZero() {
        let decimal = Decimal.zero
        let value = Money<TST>(exactly: decimal)
        #expect(value == .zero)
    }

    @Test("Money init from exact Decimal returns nil on 0 scaleFactor")
    func decimalExactInitWithZeroScaleFactor() {
        // TST_0 currency gives scale factor of 0 - see `Money.scaleFactor`
        let decimal = Decimal(42)
        #expect(Money<TST_0>(exactly: decimal) == nil)
    }

    @Test("Money init from exact Decimal with literal value")
    func decimalExactInitWithLiteralValue() throws {
        let value = try #require(Money<GBP>(exactly: 99.95))
        #expect(value.decimalValue == Decimal(99.95))
    }

    // MARK: - Decimal init from Money

    @Test("Decimal convenience initializer")
    func decimalConvenienceInit() {
        let fixed: Money<TST> = 12345
        let decimal = Decimal(exactly: fixed)
        #expect(decimal == Decimal(string: "123.45"))
    }

    @Test("Decimal NaN handling")
    func decimalNaN() {
        let moneyNaN = Money<TST>.nan
        #expect(Decimal(moneyNaN).isNaN)
    }

    // MARK: - Decimal init from exact Money

    @Test("Decimal exact init returns nil on NaN")
    func decimalExactInitNaN() {
        let moneyNaN = Money<TST>.nan
        #expect(Decimal(exactly: moneyNaN) == nil)
    }

    @Test("Decimal exact init returns value on non-NaN")
    func decimalExactInitNonNaN() {
        let decimal = Decimal(42)
        let money = Money<TST>(decimal)
        let roundTrip = Decimal(exactly: money)
        #expect(roundTrip == decimal)
    }
}
