import Testing
import SwiftMoney

@Suite("FractionalMultiplicationResult")
struct FractionalMultiplicationResultTests {

    // MARK: - Stored properties

    @Test("result is stored correctly")
    func resultIsStored() {
        let r = FractionalMultiplicationResult(
            result: Money<TST_100>(minorUnits: 1),
            actualRate: FractionalRate(numerator: 1, denominator: 101)!
        )
        #expect(r.result == Money<TST_100>(minorUnits: 1))
    }

    @Test("actualRate is stored correctly")
    func actualRateIsStored() {
        let r = FractionalMultiplicationResult(
            result: Money<TST_100>(minorUnits: 1),
            actualRate: FractionalRate(numerator: 1, denominator: 101)!
        )
        #expect(r.actualRate == FractionalRate(numerator: 1, denominator: 101)!)
    }

    // MARK: - Equatable

    @Test("identical results are equal")
    func identicalResultsAreEqual() {
        let a = FractionalMultiplicationResult(
            result: Money<TST_100>(minorUnits: 1),
            actualRate: FractionalRate(numerator: 1, denominator: 101)!
        )
        let b = FractionalMultiplicationResult(
            result: Money<TST_100>(minorUnits: 1),
            actualRate: FractionalRate(numerator: 1, denominator: 101)!
        )
        #expect(a == b)
    }

    @Test("results with different result Money are not equal")
    func differentResultsNotEqual() {
        let a = FractionalMultiplicationResult(
            result: Money<TST_100>(minorUnits: 1),
            actualRate: FractionalRate(numerator: 1, denominator: 100)!
        )
        let b = FractionalMultiplicationResult(
            result: Money<TST_100>(minorUnits: 2),
            actualRate: FractionalRate(numerator: 1, denominator: 100)!
        )
        #expect(a != b)
    }

    @Test("results with different actualRate are not equal")
    func differentActualRateNotEqual() {
        let a = FractionalMultiplicationResult(
            result: Money<TST_100>(minorUnits: 1),
            actualRate: FractionalRate(numerator: 1, denominator: 100)!
        )
        let b = FractionalMultiplicationResult(
            result: Money<TST_100>(minorUnits: 1),
            actualRate: FractionalRate(numerator: 1, denominator: 101)!
        )
        #expect(a != b)
    }

    // MARK: - CustomStringConvertible

    @Test("description includes result and actualRate")
    func descriptionIncludesResultAndRate() {
        let r = FractionalMultiplicationResult(
            result: Money<TST_100>(minorUnits: 1),
            actualRate: FractionalRate(numerator: 1, denominator: 101)!
        )
        let desc = r.description
        #expect(desc.contains("1/101"))
    }
}
