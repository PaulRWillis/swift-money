import SwiftMoney
import Testing

@Suite("Magnitude")
struct MagnitudeTests {
    @Test("Numeric magnitude for positive")
    func magnitudePositive() {
        let value: Money<TST_100> = 425
        #expect(value.magnitude == 425)
    }

    @Test("Numeric magnitude for negative")
    func magnitudeNegative() {
        let value: Money<TST_100> = -201
        #expect(value.magnitude == 201)
    }

    @Test("Numeric magnitude for NaN traps")
    func magnitudeNaN() async {
        await #expect(processExitsWith: .failure) { _ = Money<TST_100>.nan.magnitude }
    }

    @Test("Numeric magnitude for zero")
    func magnitudeZero() {
        #expect(Money<TST_100>.zero.magnitude == .zero)
    }

    @Test("Magnitude type is Money")
    func magnitudeType() {
        let value: Money<TST_100> = 42
        let magnitude: Money<TST_100> = value.magnitude
        #expect(magnitude == 42 as Money)
    }

    @Test("Magnitude of min")
    func magnitudeOfMin() {
        let min = Money<TST_100>.min
        #expect(min.magnitude == Money<TST_100>.max)
    }
}
