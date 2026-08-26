import SwiftMoney
import Testing

@Suite("Rate Tests")
struct RateTests {

    @Test("Percent and basis points denote the same rate")
    func percentAndBasisPointsAgree() {
        #expect(Rate.percent(50) == Rate.basisPoints(5000))
        #expect(Rate.percent(100) == Rate.basisPoints(10_000))
        #expect(Rate.percent(0) == Rate.basisPoints(0))
    }

    @Test("A negative percentage is a valid rate")
    func negativePercentageIsValid() {
        #expect(Rate.percent(-5) == Rate.basisPoints(-500))
    }

    @Test("Distinct rates are unequal")
    func distinctRatesAreUnequal() {
        #expect(Rate.basisPoints(1) != Rate.basisPoints(2))
    }

    @Test("Equal rates hash together")
    func equalRatesHashTogether() {
        #expect(Set([Rate.percent(50), Rate.basisPoints(5000)]).count == 1)
    }

    @Test("A rate too large to represent traps")
    func oversizedRateTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Rate.basisPoints(Int128.max))
        }
    }
}
