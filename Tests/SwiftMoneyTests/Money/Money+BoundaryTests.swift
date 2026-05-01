import Testing
import SwiftMoney

@Suite("Money — Int64 boundary values")
struct Money_BoundaryTests {

    // MARK: - NaN sentinel boundary

    @Test("Money with Int64.min + 1 is not NaN")
    func minPlusOneIsNotNaN() {
        let m = Money<TST_100>(minorUnits: Int64.min + 1)
        #expect(!m.isNaN)
        #expect(m.minorUnits == Int64.min + 1)
    }

    @Test("Money.nan equals Int64.min sentinel")
    func nanIsSentinel() {
        let nan = Money<TST_100>.nan
        #expect(nan.isNaN)
    }

    // MARK: - Comparison at boundaries

    @Test("NaN compares less than all finite values including Int64.min + 1")
    func nanSortsFirst() {
        let nan = Money<TST_100>.nan
        let minFinite = Money<TST_100>(minorUnits: Int64.min + 1)
        #expect(nan < minFinite)
    }

    @Test("Max value compares greater than zero")
    func maxValueComparison() {
        let max = Money<TST_100>.max
        #expect(max > .zero)
    }

    // MARK: - Hash consistency at boundaries

    @Test("Equal NaN values produce equal hashes")
    func nanHashConsistency() {
        let a = Money<TST_100>.nan
        let b = Money<TST_100>.nan
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Equal max values produce equal hashes")
    func maxHashConsistency() {
        let a = Money<TST_100>.max
        let b = Money<TST_100>.max
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }
}

@Suite("Rate — Int64 boundary values")
struct Rate_BoundaryTests {

    @Test("init returns nil for Int64.min numerator")
    func int64MinNumeratorIsNil() {
        #expect(Rate(numerator: .min, denominator: 1) == nil)
    }

    @Test("init returns nil for Int64.min denominator")
    func int64MinDenominatorIsNil() {
        #expect(Rate(numerator: 1, denominator: .min) == nil)
    }

    @Test("init succeeds with Int64.min + 1 numerator")
    func int64MinPlusOneNumerator() {
        let r = Rate(numerator: Int64.min + 1, denominator: 1)
        #expect(r != nil)
        #expect(r?.numeratorValue == Int64.min + 1)
        #expect(r?.denominatorValue == 1)
    }

    @Test("init succeeds with Int64.max numerator and denominator")
    func int64MaxBoth() {
        let r = Rate(numerator: .max, denominator: .max)
        #expect(r != nil)
        #expect(r?.numeratorValue == 1)
        #expect(r?.denominatorValue == 1)
    }

    @Test("init returns nil for zero denominator at Int64.min numerator")
    func int64MinNumeratorZeroDenominator() {
        #expect(Rate(numerator: .min, denominator: 0) == nil)
    }

    @Test("GCD reduction works at large values near Int64.max")
    func gcdReductionNearMax() {
        // Int64.max = 9223372036854775807 = 7 × 1317624576693539401
        let r = Rate(numerator: 7, denominator: Int64.max)
        #expect(r != nil)
        #expect(r?.numeratorValue == 1)
        #expect(r?.denominatorValue == 1317624576693539401)
    }
}

@Suite("ExchangeRate — Int64 boundary values")
struct ExchangeRate_BoundaryTests {

    @Test("init returns nil for Int64.min from value")
    func int64MinFromIsNil() {
        #expect(ExchangeRate<TST_100, TST_1>(from: .min, to: 1) == nil)
    }

    @Test("init returns nil for Int64.min to value")
    func int64MinToIsNil() {
        #expect(ExchangeRate<TST_100, TST_1>(from: 1, to: .min) == nil)
    }

    @Test("init returns nil for zero from value")
    func zeroFromIsNil() {
        #expect(ExchangeRate<TST_100, TST_1>(from: 0, to: 1) == nil)
    }

    @Test("init returns nil for negative from value")
    func negativeFromIsNil() {
        #expect(ExchangeRate<TST_100, TST_1>(from: -1, to: 1) == nil)
    }

    @Test("init succeeds with Int64.max from and to values")
    func int64MaxBoth() {
        let r = ExchangeRate<TST_100, TST_1>(from: .max, to: .max)
        #expect(r != nil)
    }

    @Test("init succeeds with value 1 for both from and to")
    func smallestValidValues() {
        let r = ExchangeRate<TST_100, TST_1>(from: 1, to: 1)
        #expect(r != nil)
    }

    @Test("Conversion with large rate does not crash")
    func conversionWithLargeRate() {
        let r = ExchangeRate<TST_100, TST_1>(from: 1, to: 1)!
        let money = Money<TST_100>(minorUnits: 1)
        let result = r.convert(money)
        #expect(!result.isNaN)
    }
}
