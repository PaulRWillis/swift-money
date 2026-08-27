import SwiftMoney
import Testing

@Suite("Margin Tests")
struct MarginTests {

    @Test("A rate in the half-open unit interval is a valid margin")
    func validMargins() {
        #expect(Margin(.percent(0)) != nil)
        #expect(Margin(.percent(2)) != nil)
        #expect(Margin(.basisPoints(5)) != nil)
        #expect(Margin(.percent(99)) != nil)
    }

    @Test("A margin of one whole or more is not representable")
    func atLeastOneIsNil() {
        #expect(Margin(.percent(100)) == nil)
        #expect(Margin(.percent(150)) == nil)
        #expect(Margin(.basisPoints(10_000)) == nil)
    }

    @Test("A negative margin is not representable")
    func negativeIsNil() {
        #expect(Margin(.percent(-1)) == nil)
        #expect(Margin(.basisPoints(-5)) == nil)
    }

    @Test("Equal margins compare equal")
    func equality() {
        #expect(Margin(.basisPoints(5)) == Margin(.basisPoints(5)))
        #expect(Margin(.percent(2)) != Margin(.percent(3)))
    }
}
