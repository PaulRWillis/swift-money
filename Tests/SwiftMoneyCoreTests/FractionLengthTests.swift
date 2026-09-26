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

    // Nineteen is the ceiling the display engine can actually render (padding multiplies by a power of
    // ten held in a UInt64, and 10^20 overflows it) — pinning both sides of that boundary here means an
    // unrenderable length is never constructible, rather than caught later as a formatting-time trap.
    @Test("Init at the widest renderable length succeeds")
    func initAtWidestRenderableLength() {
        #expect(FractionLength(exactly: 19) != nil)
    }

    @Test("Init one past the widest renderable length returns nil")
    func initPastWidestRenderableLength() {
        #expect(FractionLength(exactly: 20) == nil)
    }

    @Test("Literal: init one past the widest renderable length traps")
    func initPastWidestRenderableLengthLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = FractionLength(20)
        }
    }
}
