import Foundation
import Testing
import SwiftMoney

@Suite("Money - Rate Multiplication")
struct Money_RateMultiplicationTests {

    // MARK: - Canonical blog post examples

    @Test("100 × 1/100 = 1 (exact; effectiveRate == inputRate)")
    func canonicalExactCase () throws {
        let rate = try #require(Rate(numerator: 1, denominator: 100))
        let r = Money<TST_100>(minorUnits: 100).multiplied(by: rate)
        #expect(r.amount == Money<TST_100>(minorUnits: 1))
        #expect(r.effectiveRate == rate)
    }

    @Test("101 × 1/100 = 1 (rounded; effectiveRate becomes 1/101)")
    func canonicalRoundedCase () throws {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)))
        let expectedRate = try #require(Rate(numerator: 1, denominator: 101))
        #expect(r.amount == Money<TST_100>(minorUnits: 1))
        #expect(r.effectiveRate == expectedRate)
    }

    @Test("0 × 11/100 = 0 (effectiveRate == inputRate when input is zero)")
    func zeroInput () throws {
        let rate = try #require(Rate(numerator: 11, denominator: 100))
        let r = Money<TST_100>(minorUnits: 0).multiplied(by: rate)
        #expect(r.amount == Money<TST_100>.zero)
        #expect(r.effectiveRate == rate)
    }

    // MARK: - Round-trip invariant (parameterised)
    //
    // For all non-zero inputs: input × effectiveRate.numerator / effectiveRate.denominator
    // must exactly reproduce result.minorUnits as an integer.

    @Test("Round-trip invariant: input × effectiveRate == result",
          arguments: [
              (minorUnits: Int64(100), numerator: Int64(1), denominator: Int64(100)),
              (minorUnits: Int64(101), numerator: Int64(1), denominator: Int64(100)),
              (minorUnits: Int64(150), numerator: Int64(1), denominator: Int64(100)),
              (minorUnits: Int64(999), numerator: Int64(1), denominator: Int64(3)),
              (minorUnits: Int64(7),   numerator: Int64(11), denominator: Int64(100)),
          ])
    func roundTripInvariant(minorUnits: Int64, numerator: Int64, denominator: Int64) throws {
        let r = Money<TST_100>(minorUnits: minorUnits)
            .multiplied(by: try #require(Rate(numerator: numerator, denominator: denominator)))
        // input × (actualNumerator / actualDenominator) == result
        let reconstructed = minorUnits * r.effectiveRate.numeratorValue / r.effectiveRate.denominatorValue
        #expect(reconstructed == r.amount.minorUnits)
    }

    // MARK: - Rounding rules

    @Test("toNearestOrAwayFromZero: 150 × 1/100 = 2 (0.5 rounds away from zero)")
    func roundingNearestOrAwayFromZero () throws {
        let r = Money<TST_100>(minorUnits: 150)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)),
                        rounding: .toNearestOrAwayFromZero)
        #expect(r.amount == Money<TST_100>(minorUnits: 2))
    }

    @Test("toNearestOrEven (bankers): 250 × 1/100 = 2 (2.5 rounds to even)")
    func roundingBankers250 () throws {
        let r = Money<TST_100>(minorUnits: 250)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)),
                        rounding: .toNearestOrEven)
        #expect(r.amount == Money<TST_100>(minorUnits: 2))
    }

    @Test("toNearestOrEven (bankers): 350 × 1/100 = 4 (3.5 rounds to even)")
    func roundingBankers350 () throws {
        let r = Money<TST_100>(minorUnits: 350)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)),
                        rounding: .toNearestOrEven)
        #expect(r.amount == Money<TST_100>(minorUnits: 4))
    }

    @Test("up (ceiling): 101 × 1/100 = 2")
    func roundingUp () throws {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)),
                        rounding: .up)
        #expect(r.amount == Money<TST_100>(minorUnits: 2))
    }

    @Test("down (floor): 101 × 1/100 = 1")
    func roundingDown () throws {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)),
                        rounding: .down)
        #expect(r.amount == Money<TST_100>(minorUnits: 1))
    }

    @Test("towardZero: 101 × 1/100 = 1 (truncation, positive)")
    func roundingTowardZeroPositive () throws {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)),
                        rounding: .towardZero)
        #expect(r.amount == Money<TST_100>(minorUnits: 1))
    }

    @Test("towardZero: -101 × 1/100 = -1 (truncation, negative)")
    func roundingTowardZeroNegative () throws {
        let r = Money<TST_100>(minorUnits: -101)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)),
                        rounding: .towardZero)
        #expect(r.amount == Money<TST_100>(minorUnits: -1))
    }

    @Test("awayFromZero: 101 × 1/100 = 2 (positive)")
    func roundingAwayFromZeroPositive () throws {
        let r = Money<TST_100>(minorUnits: 101)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)),
                        rounding: .awayFromZero)
        #expect(r.amount == Money<TST_100>(minorUnits: 2))
    }

    @Test("awayFromZero: -101 × 1/100 = -2 (negative)")
    func roundingAwayFromZeroNegative () throws {
        let r = Money<TST_100>(minorUnits: -101)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)),
                        rounding: .awayFromZero)
        #expect(r.amount == Money<TST_100>(minorUnits: -2))
    }

    // MARK: - Negative input

    @Test("-101 × 1/100 = -1 with default rounding (effectiveRate normalised to 1/101)")
    func negativeInput () throws {
        let r = Money<TST_100>(minorUnits: -101)
            .multiplied(by: try #require(Rate(numerator: 1, denominator: 100)))
        let expectedRate = try #require(Rate(numerator: 1, denominator: 101))
        #expect(r.amount == Money<TST_100>(minorUnits: -1))
        // effectiveRate denominator is positive: (-(-1)) / (-(-101)) = 1/101
        #expect(r.effectiveRate == expectedRate)
    }

    // MARK: - Negative rate

    @Test("100 × -1/100 = -1 (negative rate)")
    func negativeRate () throws {
        let rate = try #require(Rate(numerator: -1, denominator: 100))
        let r = Money<TST_100>(minorUnits: 100).multiplied(by: rate)
        #expect(r.amount == Money<TST_100>(minorUnits: -1))
        #expect(r.effectiveRate == rate)
    }

    // MARK: - Integer-valued rate (whole number multiplier via Rate)

    @Test("100 × 2/1 = 200")
    func integerRate () throws {
        let expectedRate = try #require(Rate(numerator: 2, denominator: 1))
        let r = Money<TST_100>(minorUnits: 100).multiplied(by: 2)
        #expect(r.amount == Money<TST_100>(minorUnits: 200))
        #expect(r.effectiveRate == expectedRate)
    }

    // MARK: - * Rate operator

    @Test("* Rate operator delegates to multiplied(by:) with default rounding")
    func fractionalRateOperator () throws {
        let money = Money<TST_100>(minorUnits: 101)
        let rate  = try #require(Rate(numerator: 1, denominator: 100))
        let via_method   = money.multiplied(by: rate)
        let via_operator = money * rate
        #expect(via_method == via_operator)
    }

    @Test("* Rate operator: 101 × 1/100 = 1")
    func fractionalRateOperatorValue () throws {
        let rate = try #require(Rate(numerator: 1, denominator: 100))
        let expectedRate = try #require(Rate(numerator: 1, denominator: 101))
        let r = Money<TST_100>(minorUnits: 101) * rate
        #expect(r.amount == Money<TST_100>(minorUnits: 1))
        #expect(r.effectiveRate == expectedRate)
    }

    // MARK: - * Decimal operator

    @Test("* Decimal operator: 101 × Decimal(string:\"0.01\") = 1")
    func decimalOperatorFromString() throws {
        let decimal = try #require(Decimal(string: "0.01"))
        let expectedRate = try #require(Rate(numerator: 1, denominator: 101))
        let result = Money<TST_100>(minorUnits: 101) * decimal
        let r = try #require(result)
        #expect(r.amount == Money<TST_100>(minorUnits: 1))
        #expect(r.effectiveRate == expectedRate)
    }

    @Test("* Decimal operator matches * Rate for the same rate")
    func decimalOperatorMatchesRate() throws {
        let money = Money<TST_100>(minorUnits: 101)
        let decimal = try #require(Decimal(string: "0.01"))
        let rate = try #require(Rate(numerator: 1, denominator: 100))
        let decimalResult = money * decimal
        let viaDecimal = try #require(decimalResult)
        let viaRate    = money * rate
        #expect(viaDecimal == viaRate)
    }

    @Test("* Decimal operator returns nil for NaN Decimal")
    func decimalOperatorNaNReturnsNil () throws {
        #expect((Money<TST_100>(minorUnits: 100) * Decimal.nan) == nil)
    }

    // MARK: - Precondition traps

    @Test("multiplied(by:) traps on NaN input")
    func nanTraps() async {
        await #expect(processExitsWith: .failure) {
            guard let rate = Rate(numerator: 1, denominator: 100) else { return }
            _ = Money<TST_100>.nan.multiplied(by: rate)
        }
    }

    @Test("* Rate operator traps on NaN input")
    func nanOperatorTraps() async {
        await #expect(processExitsWith: .failure) {
            guard let rate = Rate(numerator: 1, denominator: 100) else { return }
            _ = Money<TST_100>.nan * rate
        }
    }
}
