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

    @Test("Equal margins hash alike, however they were written, and different margins stay apart")
    func hashing() throws {
        let percent = try #require(FX.Margin(.percent(2)))
        let basisPoints = try #require(FX.Margin(.basisPoints(200)))
        let other = try #require(FX.Margin(.percent(3)))

        #expect(percent.hashValue == basisPoints.hashValue)
        #expect(Set([percent, basisPoints, other]).count == 2)
    }
}
