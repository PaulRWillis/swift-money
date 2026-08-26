import SwiftMoney
import Testing

@Suite("Fixed Tests")
struct FixedTests {

    @Test("Zero is the value zero")
    func zero() {
        #expect(Fixed.zero == Fixed(0))
    }

    @Test("Equal values are equal and hash together")
    func equalValues() {
        #expect(Fixed(42) == Fixed(42))
        #expect(Set([Fixed(42), Fixed(42)]).count == 1)
    }

    @Test("Different values are not equal")
    func differentValues() {
        #expect(Fixed(1) != Fixed(2))
    }

    @Test("Ordering follows the value")
    func ordering() throws {
        #expect(Fixed(1) < Fixed(2))
        #expect(Fixed(-2) < Fixed(-1))
        #expect(Fixed(-1) < Fixed(1))

        let tenth = try #require(Fixed(decimal: "0.1"))
        let fifth = try #require(Fixed(decimal: "0.2"))
        #expect(tenth < fifth)
    }
}
