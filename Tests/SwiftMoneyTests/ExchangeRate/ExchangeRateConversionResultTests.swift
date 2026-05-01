import Testing
import SwiftMoney

@Suite("ExchangeRate - conversionResult(of:)")
struct ExchangeRateConversionResultTests {

    // EUR→GBP: 100 EUR cents = 85 GBP pence (GCD-reduces to 20:17)
    private let eurGbp = ExchangeRate<EUR, GBP>(from: 100, to: 85)!

    // MARK: - Exact conversion (no rounding)

    @Test("Exact conversion: 100 EUR cents → 85p, actualRate equals nominal rate")
    func exactConversion() {
        let r = eurGbp.conversionResult(of: Money<EUR>(minorUnits: 100))
        #expect(r.converted == Money<GBP>(minorUnits: 85))
        // input × nominal rate = exact integer → actualRate == nominal rate
        #expect(r.actualRate == eurGbp)
    }

    @Test("Exact conversion: 1000 EUR cents → 850p")
    func exactConversionLarger() {
        let r = eurGbp.conversionResult(of: Money<EUR>(minorUnits: 1000))
        #expect(r.converted == Money<GBP>(minorUnits: 850))
        #expect(r.actualRate != nil)
    }

    // MARK: - Rounding

    @Test("Rounding: 101 EUR cents × 17/20 = 85.85 → 86p (HALF_UP)")
    func roundingHalfUp() {
        let r = eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101))
        #expect(r.converted == Money<GBP>(minorUnits: 86))
        // actualRate = 86/101 (in lowest terms)
        #expect(r.actualRate == ExchangeRate<EUR, GBP>(from: 101, to: 86))
    }

    @Test("Rounding .down: 101 EUR cents × 17/20 = 85.85 → 85p with .down")
    func roundingDown() {
        let r = eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101), rounding: .down)
        #expect(r.converted == Money<GBP>(minorUnits: 85))
        #expect(r.actualRate == ExchangeRate<EUR, GBP>(from: 101, to: 85))
    }

    @Test("Rounding .up: 101 EUR cents × 17/20 = 85.85 → 86p with .up")
    func roundingUp() {
        let r = eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101), rounding: .up)
        #expect(r.converted == Money<GBP>(minorUnits: 86))
        #expect(r.actualRate == ExchangeRate<EUR, GBP>(from: 101, to: 86))
    }

    // MARK: - Zero input

    @Test("Zero input: converted is zero, actualRate equals nominal rate")
    func zeroInput() {
        let r = eurGbp.conversionResult(of: Money<EUR>(minorUnits: 0))
        #expect(r.converted == Money<GBP>(minorUnits: 0))
        // actualRate undefined for zero input; nominal rate returned per FractionalMultiplicationResult contract
        #expect(r.actualRate == eurGbp)
    }

    // MARK: - Non-zero input rounding to zero

    @Test("Non-zero input rounding to zero: actualRate is nil")
    func nonZeroInputRoundsToZero() {
        // 1 EUR cent at rate 1/100 (ExchangeRate(from:100, to:1)) → 0.01p → rounds to 0
        let tinyRate = ExchangeRate<EUR, GBP>(from: 100, to: 1)!
        let r = tinyRate.conversionResult(of: Money<EUR>(minorUnits: 1))
        #expect(r.converted == Money<GBP>(minorUnits: 0))
        #expect(r.actualRate == nil)
    }

    @Test("Non-zero input rounding to zero with .up: actualRate is non-nil")
    func nonZeroInputRoundsToZeroWithUp() {
        // Same scenario but .up rounds 0.01 → 1, so actualRate is non-nil
        let tinyRate = ExchangeRate<EUR, GBP>(from: 100, to: 1)!
        let r = tinyRate.conversionResult(of: Money<EUR>(minorUnits: 1), rounding: .up)
        #expect(r.converted == Money<GBP>(minorUnits: 1))
        #expect(r.actualRate != nil)
    }

    // MARK: - Negative input

    @Test("Negative input: converted is negative, actualRate is non-nil")
    func negativeInput() {
        let r = eurGbp.conversionResult(of: Money<EUR>(minorUnits: -1000))
        #expect(r.converted == Money<GBP>(minorUnits: -850))
        #expect(r.actualRate != nil)
    }

    @Test("Negative input rounding: -101 EUR cents × 17/20 = -85.85 → -86p (HALF_UP)")
    func negativeInputRounding() {
        let r = eurGbp.conversionResult(of: Money<EUR>(minorUnits: -101))
        #expect(r.converted == Money<GBP>(minorUnits: -86))
        // actualRate = Rate(_unchecked: -(-86), denominator: -(-101)) = 86/101
        #expect(r.actualRate == ExchangeRate<EUR, GBP>(from: 101, to: 86))
    }

    // MARK: - Round-trip invariant

    @Test("Round-trip invariant: input × actualRate.rate == converted")
    func roundTripInvariant() {
        // For any non-zero result, inputAmount × actualRate.rate == converted
        let inputs: [Int64] = [1, 7, 99, 100, 101, 999, 1000, 12345]
        for minorUnits in inputs {
            let money = Money<EUR>(minorUnits: minorUnits)
            let r = eurGbp.conversionResult(of: money)
            guard let actual = r.actualRate else { continue }
            let roundTrip = money.multiplied(by: actual.rate).result
            // Reinterpret as GBP to compare (result is a valid minor-unit count)
            let roundTripGBP = Money<GBP>(minorUnits: roundTrip.minorUnits)
            #expect(roundTripGBP == r.converted,
                    "Round-trip failed for \(minorUnits) EUR cents")
        }
    }

    // MARK: - convert delegates to conversionResult

    @Test("convert(_:rounding:) returns same value as conversionResult(of:rounding:).converted")
    func convertDelegatesToConversionResult() {
        let money = Money<EUR>(minorUnits: 101)
        #expect(eurGbp.convert(money) == eurGbp.conversionResult(of: money).converted)
        #expect(eurGbp.convert(money, rounding: .down)
            == eurGbp.conversionResult(of: money, rounding: .down).converted)
    }

    // MARK: - Equatable / Hashable

    @Test("ExchangeRateConversionResult equality")
    func equality() {
        let r1 = eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101))
        let r2 = eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101))
        let r3 = eurGbp.conversionResult(of: Money<EUR>(minorUnits: 100))
        #expect(r1 == r2)
        #expect(r1 != r3)
    }
}
