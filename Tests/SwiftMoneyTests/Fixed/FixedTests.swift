import SwiftMoney
import Testing

@Suite("Fixed Tests")
struct FixedTests {

    @Test("Zero has a raw value of zero")
    func zeroIsZero() {
        #expect(Fixed.zero.raw == 0)
    }

    @Test("Scale is ten to the eighteenth and matches the fractional digits")
    func scaleAndFractionalDigits() {
        #expect(Fixed.fractionalDigits == 18)
        #expect(Fixed.scale == 1_000_000_000_000_000_000)
    }

    @Test("Equal values are equal and hash together")
    func equalValues() {
        #expect(Fixed(raw: 42) == Fixed(raw: 42))
        #expect(Set([Fixed(raw: 42), Fixed(raw: 42)]).count == 1)
    }

    @Test("Different values are not equal")
    func differentValues() {
        #expect(Fixed(raw: 1) != Fixed(raw: 2))
    }

    @Test("Ordering follows the raw value")
    func orderingFollowsRaw() {
        #expect(Fixed(raw: 1) < Fixed(raw: 2))
        #expect(Fixed(raw: -2) < Fixed(raw: -1))
        #expect(Fixed(raw: -1) < Fixed(raw: 1))
        #expect(Fixed(raw: .min) < Fixed(raw: .max))
    }
}
