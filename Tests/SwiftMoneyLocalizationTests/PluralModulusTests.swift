import SwiftMoneyLocalization
import Testing

@Suite("PluralModulus Tests")
struct PluralModulusTests {

    @Test("A modulus of zero is rejected, so no division by zero can reach the engine")
    func zeroIsRejected() {
        #expect(PluralModulus(exactly: 0) == nil)
    }

    @Test("A negative modulus is rejected")
    func negativeIsRejected() {
        #expect(PluralModulus(exactly: -10) == nil)
    }

    @Test("A modulus divides a value and keeps the remainder")
    func remainderIsTheRemainder() throws {
        let modulus = try #require(PluralModulus(exactly: 10))

        #expect(modulus.remainder(of: 23) == 3)
        #expect(modulus.remainder(of: 30) == 0)
    }

    @Test("A literal modulus divides by its own value")
    func literalDivides() {
        let modulus: PluralModulus = 100

        #expect(modulus.remainder(of: 1_234) == 34)
    }
}
