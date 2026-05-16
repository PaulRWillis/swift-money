import SwiftMoney
import Testing

@Suite("Money - Magnitude")
struct Money_MagnitudeTests {
    @Test("Numeric magnitude for positive")
    func magnitudePositive() {
        let value = Money<TST_100>(minorUnits: 425)
        #expect(value.magnitude == Money<TST_100>(minorUnits: 425))
    }

    @Test("Numeric magnitude for negative")
    func magnitudeNegative() {
        let value = Money<TST_100>(minorUnits: -201)
        #expect(value.magnitude == Money<TST_100>(minorUnits: 201))
    }

    @Test("Numeric magnitude for zero")
    func magnitudeZero() {
        #expect(Money<TST_100>.zero.magnitude == .zero)
    }

    @Test("Magnitude type is Money")
    func magnitudeType() {
        let value = Money<TST_100>(minorUnits: 42)
        let magnitude: Money<TST_100> = value.magnitude
        #expect(magnitude == Money<TST_100>(minorUnits: 42))
    }

    @Test("Magnitude of min")
    func magnitudeOfMin() {
        let min = Money<TST_100>.min
        #expect(min.magnitude == Money<TST_100>.max)
    }
}
