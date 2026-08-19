import SwiftMoney
import Testing

@Suite("Ratio.Numerator Tests")
struct RatioNumeratorTests {

    // Unlike a denominator, every Int64 is a valid numerator — including zero, negatives, and both
    // extremes. That is the observable difference between the two types.
    @Test(
        "Every value is accepted",
        arguments: [0, 1, -1, 7, -7, Int64.max, Int64.min]
    )
    func acceptsEveryValue(_ raw: Int64) {
        #expect(Int64(Ratio.Numerator(raw)) == raw)
    }

    @Test("Equal values are equal, different values are not")
    func equality() {
        #expect(Ratio.Numerator(7) == Ratio.Numerator(7))
        #expect(Ratio.Numerator(7) != Ratio.Numerator(-7))
        #expect(Set([Ratio.Numerator(7), Ratio.Numerator(7), Ratio.Numerator(-7)]).count == 2)
    }

    @Test("An integer literal creates a numerator", arguments: [0, 7, -7])
    func literal(_ raw: Int64) {
        let numerator: Ratio.Numerator = Ratio.Numerator(raw)

        #expect(Int64(numerator) == raw)
    }

    @Test("A numerator describes itself as its value", arguments: [0, 7, -7, Int64.min, Int64.max])
    func description(_ raw: Int64) {
        #expect(String(describing: Ratio.Numerator(raw)) == "\(raw)")
    }

    // There is nothing for the literal to reject, so unlike Ratio.Denominator it cannot trap. The
    // unlabelled call form and the literal form are therefore the same thing, and both are total.
    @Test("A zero literal is valid, where a denominator's would trap")
    func zeroLiteralIsValid() {
        let numerator: Ratio.Numerator = 0

        #expect(Int64(numerator) == 0)
        #expect(Int64(Ratio.Numerator(0)) == 0)
    }
}
