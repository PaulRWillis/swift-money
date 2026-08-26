import SwiftMoney
import Testing

@Suite("Rate Basis Points Tests")
struct RateBasisPointsTests {

    @Test("Whole basis points read back exactly")
    func wholeBasisPointsExact() throws {
        #expect(Rate.basisPoints(250).wholeBasisPoints == 250)
        #expect(Rate.percent(1).wholeBasisPoints == 100)
        #expect(Rate.basisPoints(-250).wholeBasisPoints == -250)
        #expect(try #require(Rate(string: "0.5")).wholeBasisPoints == 5000)
    }

    @Test("A fraction of a basis point has no whole reading")
    func fractionalBasisPointIsNil() throws {
        #expect(try #require(Rate(string: "0.00005")).wholeBasisPoints == nil)   // half a basis point
    }

    @Test("Basis points round by the caller's rule")
    func basisPointsRounding() throws {
        let halfPoint = try #require(Rate(string: "0.00005"))                     // 0.5 basis points
        #expect(halfPoint.basisPoints(rounding: .up) == 1)
        #expect(halfPoint.basisPoints(rounding: .down) == 0)
        #expect(halfPoint.basisPoints(rounding: .toNearestOrEven) == 0)          // ties to even
        #expect(Rate.basisPoints(250).basisPoints(rounding: .up) == 250)         // already whole, no step
    }
}
