import SwiftMoneyCore
import Testing

@Suite("FractionLength Tests")
struct FractionLengthTests {

    @Test("Init from zero succeeds")
    func initFromZero() {
        #expect(FractionLength(exactly: 0) != nil)
    }

    @Test("Init from a negative value returns nil")
    func initFromNegative() {
        #expect(FractionLength(exactly: -1) == nil)
    }

    @Test("Literal: init from a negative value traps")
    func initFromNegativeLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = FractionLength(-1)
        }
    }
}
