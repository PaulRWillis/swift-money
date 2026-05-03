import Testing
import SwiftMoney

@Suite("RateCalculation")
struct RateCalculationTests {

    // MARK: - Stored properties

    @Test("result is stored correctly")
    func resultIsStored () throws {
        let r = RateCalculation(
            amount: Money<TST_100>(minorUnits: 1),
            effectiveRate: try #require(Rate(numerator: 1, denominator: 101))
        )
        #expect(r.amount == Money<TST_100>(minorUnits: 1))
    }

    @Test("effectiveRate is stored correctly")
    func effectiveRateIsStored () throws {
        let r = RateCalculation(
            amount: Money<TST_100>(minorUnits: 1),
            effectiveRate: try #require(Rate(numerator: 1, denominator: 101))
        )
        let expectedRate = try #require(Rate(numerator: 1, denominator: 101))
        #expect(r.effectiveRate == expectedRate)
    }

    // MARK: - Equatable

    @Test("identical results are equal")
    func identicalResultsAreEqual () throws {
        let a = RateCalculation(
            amount: Money<TST_100>(minorUnits: 1),
            effectiveRate: try #require(Rate(numerator: 1, denominator: 101))
        )
        let b = RateCalculation(
            amount: Money<TST_100>(minorUnits: 1),
            effectiveRate: try #require(Rate(numerator: 1, denominator: 101))
        )
        #expect(a == b)
    }

    @Test("results with different result Money are not equal")
    func differentResultsNotEqual () throws {
        let a = RateCalculation(
            amount: Money<TST_100>(minorUnits: 1),
            effectiveRate: try #require(Rate(numerator: 1, denominator: 100))
        )
        let b = RateCalculation(
            amount: Money<TST_100>(minorUnits: 2),
            effectiveRate: try #require(Rate(numerator: 1, denominator: 100))
        )
        #expect(a != b)
    }

    @Test("results with different effectiveRate are not equal")
    func differentActualRateNotEqual () throws {
        let a = RateCalculation(
            amount: Money<TST_100>(minorUnits: 1),
            effectiveRate: try #require(Rate(numerator: 1, denominator: 100))
        )
        let b = RateCalculation(
            amount: Money<TST_100>(minorUnits: 1),
            effectiveRate: try #require(Rate(numerator: 1, denominator: 101))
        )
        #expect(a != b)
    }

    // MARK: - CustomStringConvertible

    @Test("description includes result and effectiveRate")
    func descriptionIncludesResultAndRate () throws {
        let r = RateCalculation(
            amount: Money<TST_100>(minorUnits: 1),
            effectiveRate: try #require(Rate(numerator: 1, denominator: 101))
        )
        let desc = r.description
        #expect(desc.contains("1/101"))
    }
}
