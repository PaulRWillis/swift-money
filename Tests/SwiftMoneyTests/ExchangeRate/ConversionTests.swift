import Testing
import SwiftMoney

@Suite("ExchangeRate - conversionResult(of:)")
struct ConversionTests {

    // EUR→GBP: 100 EUR cents = 85 GBP pence (GCD-reduces to 20:17)
    private var eurGbp: ExchangeRate<EUR, GBP> {
        get throws {
            try #require(ExchangeRate<EUR, GBP>(from: 100, to: 85))
        }
    }

    // MARK: - Exact conversion (no rounding)

    @Test("Exact conversion: 100 EUR cents → 85p, effectiveRate equals nominal rate")
    func exactConversion() throws {
        let rate = try eurGbp
        let conversion = rate.conversionResult(of: Money<EUR>(minorUnits: 100))
        #expect(conversion.amount == Money<GBP>(minorUnits: 85))
        // input × nominal rate = exact integer → effectiveRate == nominal rate
        #expect(conversion.effectiveRate == rate)
    }

    @Test("Exact conversion: 1000 EUR cents → 850p")
    func exactConversionLarger() throws {
        let conversion = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 1000))
        #expect(conversion.amount == Money<GBP>(minorUnits: 850))
        #expect(conversion.effectiveRate != nil)
    }

    // MARK: - Rounding

    @Test("Rounding: 101 EUR cents × 17/20 = 85.85 → 86p (HALF_UP)")
    func roundingHalfUp() throws {
        let conversion = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101))
        #expect(conversion.amount == Money<GBP>(minorUnits: 86))
        // effectiveRate = 86/101 (in lowest terms)
        #expect(conversion.effectiveRate == ExchangeRate<EUR, GBP>(from: 101, to: 86))
    }

    @Test("Rounding .down: 101 EUR cents × 17/20 = 85.85 → 85p with .down")
    func roundingDown() throws {
        let conversion = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101), rounding: .down)
        #expect(conversion.amount == Money<GBP>(minorUnits: 85))
        #expect(conversion.effectiveRate == ExchangeRate<EUR, GBP>(from: 101, to: 85))
    }

    @Test("Rounding .up: 101 EUR cents × 17/20 = 85.85 → 86p with .up")
    func roundingUp() throws {
        let conversion = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101), rounding: .up)
        #expect(conversion.amount == Money<GBP>(minorUnits: 86))
        #expect(conversion.effectiveRate == ExchangeRate<EUR, GBP>(from: 101, to: 86))
    }

    // MARK: - Zero input

    @Test("Zero input: converted is zero, effectiveRate equals nominal rate")
    func zeroInput() throws {
        let rate = try eurGbp
        let conversion = rate.conversionResult(of: Money<EUR>(minorUnits: 0))
        #expect(conversion.amount == Money<GBP>(minorUnits: 0))
        // effectiveRate undefined for zero input; nominal rate returned per RateCalculation contract
        #expect(conversion.effectiveRate == rate)
    }

    // MARK: - Non-zero input rounding to zero

    @Test("Non-zero input rounding to zero: effectiveRate is nil")
    func nonZeroInputRoundsToZero() throws {
        // 1 EUR cent at rate 1/100 (ExchangeRate(from:100, to:1)) → 0.01p → rounds to 0
        let tinyRate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 1))
        let conversion = tinyRate.conversionResult(of: Money<EUR>(minorUnits: 1))
        #expect(conversion.amount == Money<GBP>(minorUnits: 0))
        #expect(conversion.effectiveRate == nil)
    }

    @Test("Non-zero input rounding to zero with .up: effectiveRate is non-nil")
    func nonZeroInputRoundsToZeroWithUp() throws {
        // Same scenario but .up rounds 0.01 → 1, so effectiveRate is non-nil
        let tinyRate = try #require(ExchangeRate<EUR, GBP>(from: 100, to: 1))
        let conversion = tinyRate.conversionResult(of: Money<EUR>(minorUnits: 1), rounding: .up)
        #expect(conversion.amount == Money<GBP>(minorUnits: 1))
        #expect(conversion.effectiveRate != nil)
    }

    // MARK: - Negative input

    @Test("Negative input: converted is negative, effectiveRate is non-nil")
    func negativeInput() throws {
        let conversion = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: -1000))
        #expect(conversion.amount == Money<GBP>(minorUnits: -850))
        #expect(conversion.effectiveRate != nil)
    }

    @Test("Negative input rounding: -101 EUR cents × 17/20 = -85.85 → -86p (HALF_UP)")
    func negativeInputRounding() throws {
        let conversion = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: -101))
        #expect(conversion.amount == Money<GBP>(minorUnits: -86))
        // effectiveRate = Rate(_unchecked: -(-86), denominator: -(-101)) = 86/101
        #expect(conversion.effectiveRate == ExchangeRate<EUR, GBP>(from: 101, to: 86))
    }

    // MARK: - Round-trip invariant

    @Test("Round-trip invariant: input × effectiveRate.rate == converted")
    func roundTripInvariant() throws {
        // For any non-zero result, inputAmount × effectiveRate.rate == converted
        let inputs: [Int64] = [1, 7, 99, 100, 101, 999, 1000, 12345]
        for minorUnits in inputs {
            let money = Money<EUR>(minorUnits: minorUnits)
            let conversion = try eurGbp.conversionResult(of: money)
            guard let actual = conversion.effectiveRate else { continue }
            let roundTrip = money.multiplied(by: actual.rate).amount
            // Reinterpret as GBP to compare (result is a valid minor-unit count)
            let roundTripGBP = Money<GBP>(minorUnits: roundTrip.minorUnits)
            #expect(roundTripGBP == conversion.amount,
                    "Round-trip failed for \(minorUnits) EUR cents")
        }
    }

    // MARK: - convert delegates to conversionResult

    @Test("convert(_:rounding:) returns same value as conversionResult(of:rounding:).amount")
    func convertDelegatesToConversionResult() throws {
        let rate = try eurGbp
        let money = Money<EUR>(minorUnits: 101)
        #expect(rate.convert(money) == rate.conversionResult(of: money).amount)
        #expect(rate.convert(money, rounding: .down)
            == rate.conversionResult(of: money, rounding: .down).amount)
    }

    // MARK: - Equatable / Hashable

    @Test("Conversion equality")
    func equality() throws {
        let conversion1 = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101))
        let conversion2 = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101))
        let conversion3 = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 100))
        #expect(conversion1 == conversion2)
        #expect(conversion1 != conversion3)
    }

    @Test("Equal Conversions deduplicate in a Set")
    func hashableDeduplication() throws {
        let conversion1 = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101))
        let conversion2 = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101))
        let set: Set<Conversion<EUR, GBP>> = [conversion1, conversion2]
        #expect(set.count == 1)
    }

    @Test("Distinct Conversions coexist in a Set")
    func hashableDistinct() throws {
        let conversion1 = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 101))
        let conversion2 = try eurGbp.conversionResult(of: Money<EUR>(minorUnits: 100))
        let set: Set<Conversion<EUR, GBP>> = [conversion1, conversion2]
        #expect(set.count == 2)
    }
}
