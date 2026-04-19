import SwiftMoney
import Testing

@Suite("Magnitude")
struct MagnitudeTests {
    @Test("Numeric magnitude for positive")
    func magnitudePositive() {
        let value: Money<TST> = 425
        #expect(value.magnitude == 425)
    }

    @Test("Numeric magnitude for negative")
    func magnitudeNegative() {
        let value: Money<TST> = -201
        #expect(value.magnitude == 201)
    }

    @Test("Numeric magnitude for NaN traps")
    func magnitudeNaN() async {
        await #expect(processExitsWith: .failure) { _ = Money<TST>.nan.magnitude }
    }

    @Test("Numeric magnitude for zero")
    func magnitudeZero() {
        #expect(Money<TST>.zero.magnitude == .zero)
    }

    @Test("Magnitude type is Money")
    func magnitudeType() {
        let value: Money<TST> = 42
        let magnitude: Money<TST> = value.magnitude
        #expect(magnitude == 42 as Money)
    }

    @Test("Magnitude of .min")
    func magnitudeOfMin() {
        let min = Money<TST>.min
        #expect(min.magnitude == Money<TST>.max)
    }
}
