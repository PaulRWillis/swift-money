import SwiftMoney
import Testing

@Suite("Wide256Magnitude Tests")
struct Wide256MagnitudeTests {

    @Test("Multiplying then dividing by one factor recovers the other exactly")
    func roundTrip() throws {
        let product = Wide256Magnitude(.max, times: 3)

        let result = try #require(product.quotientAndRemainder(dividingBy: .max))

        #expect(result.quotient == 3)
        #expect(result.remainder == 0)
    }

    @Test("Divides a known value into quotient and remainder")
    func knownDivision() throws {
        let product = Wide256Magnitude(7, times: 1000)

        let result = try #require(product.quotientAndRemainder(dividingBy: 999))

        #expect(result.quotient == 7)
        #expect(result.remainder == 7)
    }

    @Test("Divides a full 256-bit value with a non-zero high word")
    func highWordDivision() throws {
        let product = Wide256Magnitude(UInt128(1) << 64, times: UInt128(1) << 64)

        let result = try #require(product.quotientAndRemainder(dividingBy: 2))

        #expect(result.quotient == UInt128(1) << 127)
        #expect(result.remainder == 0)
    }

    @Test("A quotient that needs more than one word returns nil")
    func overflowingQuotientIsNil() {
        let product = Wide256Magnitude(.max, times: .max)

        #expect(product.quotientAndRemainder(dividingBy: 1) == nil)
    }
}
