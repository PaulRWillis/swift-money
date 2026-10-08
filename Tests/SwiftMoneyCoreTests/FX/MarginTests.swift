import SwiftMoneyCore
import Testing

@Suite("Margin Tests")
struct MarginTests {

    @Test("A rate in the half-open unit interval is a valid margin")
    func validMargins() {
        #expect(FX.Margin(.percent(0)) != nil)
        #expect(FX.Margin(.percent(2)) != nil)
        #expect(FX.Margin(.basisPoints(5)) != nil)
        #expect(FX.Margin(.percent(99)) != nil)
    }

    @Test("A margin of one whole or more is not representable")
    func atLeastOneIsNil() {
        #expect(FX.Margin(.percent(100)) == nil)
        #expect(FX.Margin(.percent(150)) == nil)
        #expect(FX.Margin(.basisPoints(10_000)) == nil)
    }

    @Test("A negative margin is not representable")
    func negativeIsNil() {
        #expect(FX.Margin(.percent(-1)) == nil)
        #expect(FX.Margin(.basisPoints(-5)) == nil)
    }

    @Test("Equal margins compare equal")
    func equality() {
        #expect(FX.Margin(.basisPoints(5)) == FX.Margin(.basisPoints(5)))
        #expect(FX.Margin(.percent(2)) != FX.Margin(.percent(3)))
    }
}
