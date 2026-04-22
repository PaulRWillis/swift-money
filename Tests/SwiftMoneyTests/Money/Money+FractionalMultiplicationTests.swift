import Foundation
import Testing
import SwiftMoney

@Suite("Money - Fractional Multiplication")
struct Money_FractionalMultiplicationTests {

    // MARK: - Canonical blog post examples

    @Test("100 × 1/100 = 1 (exact; actualRate == inputRate)")
    func canonicalExactCase() {
        let r = Money<TST_100>(minorUnits: 100)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!)
        #expect(r.result == Money<TST_100>(minorUnits: 1))
        #expect(r.actualRate == FractionalRate(numerator: 1, denominator: 100)!)
    }

    @Test("101 × 1/100 = 1 (rounded; actualRate becomes 1/101)")
    func canonicalRoundedCase() {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!)
        #expect(r.result == Money<TST_100>(minorUnits: 1))
        #expect(r.actualRate == FractionalRate(numerator: 1, denominator: 101)!)
    }

    @Test("0 × 11/100 = 0 (actualRate == inputRate when input is zero)")
    func zeroInput() {
        let r = Money<TST_100>(minorUnits: 0)
            .multiplied(by: FractionalRate(numerator: 11, denominator: 100)!)
        #expect(r.result == Money<TST_100>.zero)
        #expect(r.actualRate == FractionalRate(numerator: 11, denominator: 100)!)
    }

    // MARK: - Round-trip invariant (parameterised)
    //
    // For all non-zero inputs: input × actualRate.numerator / actualRate.denominator
    // must exactly reproduce result.minorUnits as an integer.

    @Test("Round-trip invariant: input × actualRate == result",
          arguments: [
              (minorUnits: Int64(100), numerator: Int64(1), denominator: Int64(100)),
              (minorUnits: Int64(101), numerator: Int64(1), denominator: Int64(100)),
              (minorUnits: Int64(150), numerator: Int64(1), denominator: Int64(100)),
              (minorUnits: Int64(999), numerator: Int64(1), denominator: Int64(3)),
              (minorUnits: Int64(7),   numerator: Int64(11), denominator: Int64(100)),
          ])
    func roundTripInvariant(minorUnits: Int64, numerator: Int64, denominator: Int64) {
        let r = Money<TST_100>(minorUnits: minorUnits)
            .multiplied(by: FractionalRate(numerator: numerator, denominator: denominator)!)
        // input × (actualNumerator / actualDenominator) == result
        let reconstructed = minorUnits * r.actualRate.numeratorValue / r.actualRate.denominatorValue
        #expect(reconstructed == r.result.minorUnits)
    }

    // MARK: - Rounding rules

    @Test("toNearestOrAwayFromZero: 150 × 1/100 = 2 (0.5 rounds away from zero)")
    func roundingNearestOrAwayFromZero() {
        let r = Money<TST_100>(minorUnits: 150)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!,
                        rounding: .toNearestOrAwayFromZero)
        #expect(r.result == Money<TST_100>(minorUnits: 2))
    }

    @Test("toNearestOrEven (bankers): 250 × 1/100 = 2 (2.5 rounds to even)")
    func roundingBankers250() {
        let r = Money<TST_100>(minorUnits: 250)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!,
                        rounding: .toNearestOrEven)
        #expect(r.result == Money<TST_100>(minorUnits: 2))
    }

    @Test("toNearestOrEven (bankers): 350 × 1/100 = 4 (3.5 rounds to even)")
    func roundingBankers350() {
        let r = Money<TST_100>(minorUnits: 350)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!,
                        rounding: .toNearestOrEven)
        #expect(r.result == Money<TST_100>(minorUnits: 4))
    }

    @Test("up (ceiling): 101 × 1/100 = 2")
    func roundingUp() {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!,
                        rounding: .up)
        #expect(r.result == Money<TST_100>(minorUnits: 2))
    }

    @Test("down (floor): 101 × 1/100 = 1")
    func roundingDown() {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!,
                        rounding: .down)
        #expect(r.result == Money<TST_100>(minorUnits: 1))
    }

    @Test("towardZero: 101 × 1/100 = 1 (truncation, positive)")
    func roundingTowardZeroPositive() {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!,
                        rounding: .towardZero)
        #expect(r.result == Money<TST_100>(minorUnits: 1))
    }

    @Test("towardZero: -101 × 1/100 = -1 (truncation, negative)")
    func roundingTowardZeroNegative() {
        let r = Money<TST_100>(minorUnits: -101)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!,
                        rounding: .towardZero)
        #expect(r.result == Money<TST_100>(minorUnits: -1))
    }

    @Test("awayFromZero: 101 × 1/100 = 2 (positive)")
    func roundingAwayFromZeroPositive() {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!,
                        rounding: .awayFromZero)
        #expect(r.result == Money<TST_100>(minorUnits: 2))
    }

    @Test("awayFromZero: -101 × 1/100 = -2 (negative)")
    func roundingAwayFromZeroNegative() {
        let r = Money<TST_100>(minorUnits: -101)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!,
                        rounding: .awayFromZero)
        #expect(r.result == Money<TST_100>(minorUnits: -2))
    }

    // MARK: - Negative input

    @Test("-101 × 1/100 = -1 with default rounding (actualRate normalised to 1/101)")
    func negativeInput() {
        let r = Money<TST_100>(minorUnits: -101)
            .multiplied(by: FractionalRate(numerator: 1, denominator: 100)!)
        #expect(r.result == Money<TST_100>(minorUnits: -1))
        // actualRate denominator is positive: (-(-1)) / (-(-101)) = 1/101
        #expect(r.actualRate == FractionalRate(numerator: 1, denominator: 101)!)
    }

    // MARK: - Negative rate

    @Test("100 × -1/100 = -1 (negative rate)")
    func negativeRate() {
        let r = Money<TST_100>(minorUnits: 100)
            .multiplied(by: FractionalRate(numerator: -1, denominator: 100)!)
        #expect(r.result == Money<TST_100>(minorUnits: -1))
        #expect(r.actualRate == FractionalRate(numerator: -1, denominator: 100)!)
    }

    // MARK: - Integer-valued rate (whole number multiplier via FractionalRate)

    @Test("100 × 2/1 = 200")
    func integerRate() {
        let r = Money<TST_100>(minorUnits: 100).multiplied(by: 2)
        #expect(r.result == Money<TST_100>(minorUnits: 200))
        #expect(r.actualRate == FractionalRate(numerator: 2, denominator: 1)!)
    }

    // MARK: - * FractionalRate operator

    @Test("* FractionalRate operator delegates to multiplied(by:) with default rounding")
    func fractionalRateOperator() {
        let money = Money<TST_100>(minorUnits: 101)
        let rate  = FractionalRate(numerator: 1, denominator: 100)!
        let via_method   = money.multiplied(by: rate)
        let via_operator = money * rate
        #expect(via_method == via_operator)
    }

    @Test("* FractionalRate operator: 101 × 1/100 = 1")
    func fractionalRateOperatorValue() {
        let r = Money<TST_100>(minorUnits: 101) * FractionalRate(numerator: 1, denominator: 100)!
        #expect(r.result == Money<TST_100>(minorUnits: 1))
        #expect(r.actualRate == FractionalRate(numerator: 1, denominator: 101)!)
    }

    // MARK: - * Decimal operator

    @Test("* Decimal operator: 101 × Decimal(string:\"0.01\") = 1")
    func decimalOperatorFromString() {
        let r = (Money<TST_100>(minorUnits: 101) * Decimal(string: "0.01")!)!
        #expect(r.result == Money<TST_100>(minorUnits: 1))
        #expect(r.actualRate == FractionalRate(numerator: 1, denominator: 101)!)
    }

    @Test("* Decimal operator matches * FractionalRate for the same rate")
    func decimalOperatorMatchesFractionalRate() {
        let money = Money<TST_100>(minorUnits: 101)
        let viaDecimal = (money * Decimal(string: "0.01")!)!
        let viaRate    = money * FractionalRate(numerator: 1, denominator: 100)!
        #expect(viaDecimal == viaRate)
    }

    @Test("* Decimal operator returns nil for NaN Decimal")
    func decimalOperatorNaNReturnsNil() {
        #expect((Money<TST_100>(minorUnits: 100) * Decimal.nan) == nil)
    }

    // MARK: - Precondition traps

    @Test("multiplied(by:) traps on NaN input")
    func nanTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>.nan.multiplied(by: FractionalRate(numerator: 1, denominator: 100)!)
        }
    }

    @Test("* FractionalRate operator traps on NaN input")
    func nanOperatorTraps() async {
        await #expect(processExitsWith: .failure) {
            _ = Money<TST_100>.nan * FractionalRate(numerator: 1, denominator: 100)!
        }
    }
}
