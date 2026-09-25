import SwiftMoneyCore
import Testing

@Suite("DirectionalMark")
struct DirectionalMarkTests {

    @Test("Each mark renders its own Unicode scalar")
    func rendersItsScalar() {
        #expect(DirectionalMark.leftToRight.scalar == "\u{200E}")
        #expect(DirectionalMark.rightToLeft.scalar == "\u{200F}")
    }

    @Test("A mark scalar round-trips back to its case")
    func recognizesMarkScalars() throws {
        let leftToRight = try #require(DirectionalMark("\u{200E}"))
        #expect(leftToRight == .leftToRight)

        let rightToLeft = try #require(DirectionalMark("\u{200F}"))
        #expect(rightToLeft == .rightToLeft)
    }

    @Test("A scalar that is not a directional mark is rejected")
    func rejectsNonMarkScalars() {
        #expect(DirectionalMark("A") == nil)
        #expect(DirectionalMark("\u{00A0}") == nil)
        #expect(DirectionalMark(" ") == nil)
    }
}
