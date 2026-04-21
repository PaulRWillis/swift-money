import Foundation
import SwiftMoney
import Testing

@Suite("Decimal Conversions")
struct DecimalTests {

    // MARK: - decimalValue

    @Test("decimalValue returns Decimal.nan for Money.nan")
    func decimalValueForNaN() {
        let moneyNaN = Money<TST_100>.nan
        #expect(moneyNaN.decimalValue == .nan)
    }

    @Test("decimalValue returns correct Decimal for Money")
    func decimalValue() {
        let value = Money<TST_100>(minorUnits: 42)
        #expect(value.decimalValue == Decimal(0.42))
    }

    // MARK: - Money init from Decimal

    @Test("Money init from Decimal with exact precision currency allows")
    func decimalInitWithExactPrecision() async {
        await #expect(processExitsWith: .success) {
            let decimal = Decimal(1.23) // valid money represenation in TST_100 currency
            let value = Money<TST_100>(decimal)
            #expect(value.minorUnits == 123)
        }
    }

    @Test("Money init from Decimal traps on greater precision than currency allows")
    func decimalInitWithGreaterPrecision() async {
        await #expect(processExitsWith: .failure) {
            let decimal = Decimal(1.234) // invalid money representation in TST_100 currency
            _ = Money<TST_100>(decimal)
        }
    }

    @Test("Money init from Decimal with less precision than currency allows")
    func decimalInitWithLessPrecision() async {
        await #expect(processExitsWith: .success) {
            let decimal = Decimal(1.2)
            let value = Money<TST_100>(decimal)
            #expect(value.minorUnits == 120)
        }

        await #expect(processExitsWith: .success) {
            let decimal = Decimal(1)
            let value = Money<TST_100>(decimal)
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
            _ = Money<TST_100>(decimal)
        }
    }

    @Test("Money init from Decimal traps on overflow")
    func decimalInitTrapsOnOverflow() async {
        await #expect(processExitsWith: .failure) {
            let decimal = Decimal.greatestFiniteMagnitude
            _ = Money<TST_100>(decimal)
        }
    }

    @Test("Money init from Decimal traps on underflow")
    func decimalInitTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            let decimal = Decimal.leastFiniteMagnitude
            _ = Money<TST_100>(decimal)
        }
    }

    @Test("Money init from Decimal with zero")
    func decimalInitWithZero() {
        let decimal = Decimal.zero
        let value = Money<TST_100>(decimal)
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
        let decimal = Decimal(1.23) // valid money represenation in TST_100 currency
        let value = try #require(Money<TST_100>(exactly: decimal))
        #expect(value.minorUnits == 123)
    }

    @Test("Money init from exact Decimal returns nil on greater precision than currency allows")
    func decimalExactInitWithGreaterPrecision() {
        let decimal = Decimal(1.234) // invalid money representation in TST_100 currency
        #expect(Money<TST_100>(exactly: decimal) == nil)
    }

    @Test("Money init from exact Decimal with less precision than currency allows")
    func decimalExactInitWithLessPrecision() throws {
        let decimal = Decimal(1)
        let value = try #require(Money<TST_100>(exactly: decimal))
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
        #expect(Money<TST_100>(exactly: decimal) == nil)
    }

    @Test("Money init from exact Decimal returns nil on overflow")
    func decimalExactInitTrapsOnOverflow() {
        let decimal = Decimal.greatestFiniteMagnitude
        #expect(Money<TST_100>(exactly: decimal) == nil)
    }

    @Test("Money init from exact Decimal returns nil on underflow")
    func decimalExactInitTrapsOnUnderflow() {
        let decimal = Decimal.leastFiniteMagnitude
        #expect(Money<TST_100>(exactly: decimal) == nil)
    }

    @Test("Money init from exact Decimal with zero")
    func decimalExactInitWithZero() {
        let decimal = Decimal.zero
        let value = Money<TST_100>(exactly: decimal)
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
        let fixed: Money<TST_100> = 12345
        let decimal = Decimal(exactly: fixed)
        #expect(decimal == Decimal(string: "123.45"))
    }

    @Test("Decimal NaN handling")
    func decimalNaN() {
        let moneyNaN = Money<TST_100>.nan
        #expect(Decimal(moneyNaN).isNaN)
    }

    // MARK: - Decimal init from exact Money

    @Test("Decimal exact init returns nil on NaN")
    func decimalExactInitNaN() {
        let moneyNaN = Money<TST_100>.nan
        #expect(Decimal(exactly: moneyNaN) == nil)
    }

    @Test("Decimal exact init returns value on non-NaN")
    func decimalExactInitNonNaN() {
        let decimal = Decimal(42)
        let money = Money<TST_100>(decimal)
        let roundTrip = Decimal(exactly: money)
        #expect(roundTrip == decimal)
    }

    // MARK: - Decimal inits for different minimal quantisations

    @Test("Money init from decimal for currency with 1:100 major:minor unit ratio")
    func decimalInitFor100MinorUnitCurrency() {
        let decimal = Decimal(10.99) // Analogous to £10.99
        let value = Money<TST_100>(decimal)
        #expect(value.decimalValue == decimal)
        #expect(value.minorUnits == 1099)
    }

    @Test("Money init from decimal for currency with no minor units")
    func decimalInitForNoMinorUnitCurrency() {
        let decimal = Decimal(153.0) // Analogous to ¥153 (153 JPY).
        let value = Money<TST_1>(decimal)
        #expect(value.decimalValue == decimal)
        #expect(value.minorUnits == 153)
    }

    @Test("Money init from decimal for currency with no minor units - traps on invalid decimal")
    func decimalInitForNoMinorUnitCurrencyTrapsOnInvalidDecimal() async {
        await #expect(processExitsWith: .failure) {
            let decimal = Decimal(153.12) // Analogous to invalid ¥153.12 (153.12 JPY).
            _ = Money<TST_1>(decimal)
        }
    }

    // 1 bitcoin (1₿ or 1 BTC) = 100_000_000 "satoshis".
    // 1 satoshi = 0.00_000_001 BTC.
    @Test("Money init from decimal for BTC analogue")
    func decimalInitForBTCAnalogue() {
        let decimal = Decimal(153.0) // Analogous to 153 BTC.
        let value = Money<TST_100_000_000>(decimal)
        #expect(value.decimalValue == decimal)
        #expect(value.minorUnits == 15_300_000_000)
    }

    @Test("Money init from decimal for BTC analogue traps on underflow")
    func decimalInitForBTCAnalogueTrapsOnUnderflow() async {
        await #expect(processExitsWith: .failure) {
            let decimal = Decimal(1.000_000_001) // Analogous to invalid 1.000_000_001 BTC
            _ = Money<TST_100_000_000>(decimal)
        }
    }

    @Test("Money init from decimal for BTC analogue - min satoshi edge case")
    func decimalInitForBTCAnalogueMin() throws {
        let decimal = try #require(Decimal(string: "1.00000001")) // Analogous to 1.00_000_001 BTC
        let value = Money<TST_100_000_000>(decimal)
        #expect(value.decimalValue == decimal)
        #expect(value.minorUnits == 100_000_001)
    }

    @Test("Money init from decimal for BTC analogue - max satoshi edge case")
    func decimalInitForBTCAnalogueMax() throws {
        let scaledInt64Max = Int64.max / TST_100_000_000.minorUnitRatio
        let decimal = try #require(Decimal(string: String(scaledInt64Max)))
        let value = Money<TST_100_000_000>(decimal)
        #expect(value.decimalValue == decimal)
        #expect(value.minorUnits == 92_233_720_368_00_000_000) // 92,233,720,368.00_000_000 bitcoin
    }

    @Test("Money init from decimal for BTC analogue - overflow")
    func decimalInitForBTCAnalogueOverflow() async throws {
        await #expect(processExitsWith: .failure) {
            let overflowByOne = (Int64.max / TST_100_000_000.minorUnitRatio) + 1
            let decimal = try #require(Decimal(string: String(overflowByOne)))
            _ = Money<TST_100_000_000>(decimal)
        }
    }
}
