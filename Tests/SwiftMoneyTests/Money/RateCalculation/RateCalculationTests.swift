import Testing
import SwiftMoney

@Suite("RateCalculation")
struct RateCalculationTests {

    // MARK: - Stored properties

    @Test("result is stored correctly")
    func resultIsStored() {
        let r = RateCalculation(
            result: Money<TST_100>(minorUnits: 1),
            effectiveRate: Rate(numerator: 1, denominator: 101)!
        )
        #expect(r.result == Money<TST_100>(minorUnits: 1))
    }

    @Test("effectiveRate is stored correctly")
    func effectiveRateIsStored() {
        let r = RateCalculation(
            result: Money<TST_100>(minorUnits: 1),
            effectiveRate: Rate(numerator: 1, denominator: 101)!
        )
        #expect(r.effectiveRate == Rate(numerator: 1, denominator: 101)!)
    }

    // MARK: - Equatable

    @Test("identical results are equal")
    func identicalResultsAreEqual() {
        let a = RateCalculation(
            result: Money<TST_100>(minorUnits: 1),
            effectiveRate: Rate(numerator: 1, denominator: 101)!
        )
        let b = RateCalculation(
            result: Money<TST_100>(minorUnits: 1),
            effectiveRate: Rate(numerator: 1, denominator: 101)!
        )
        #expect(a == b)
    }

    @Test("results with different result Money are not equal")
    func differentResultsNotEqual() {
        let a = RateCalculation(
            result: Money<TST_100>(minorUnits: 1),
            effectiveRate: Rate(numerator: 1, denominator: 100)!
        )
        let b = RateCalculation(
            result: Money<TST_100>(minorUnits: 2),
            effectiveRate: Rate(numerator: 1, denominator: 100)!
        )
        #expect(a != b)
    }

    @Test("results with different effectiveRate are not equal")
    func differentActualRateNotEqual() {
        let a = RateCalculation(
            result: Money<TST_100>(minorUnits: 1),
            effectiveRate: Rate(numerator: 1, denominator: 100)!
        )
        let b = RateCalculation(
            result: Money<TST_100>(minorUnits: 1),
            effectiveRate: Rate(numerator: 1, denominator: 101)!
        )
        #expect(a != b)
    }

    // MARK: - CustomStringConvertible

    @Test("description includes result and effectiveRate")
    func descriptionIncludesResultAndRate() {
        let r = RateCalculation(
            result: Money<TST_100>(minorUnits: 1),
            effectiveRate: Rate(numerator: 1, denominator: 101)!
        )
        let desc = r.description
        #expect(desc.contains("1/101"))
    }
}
