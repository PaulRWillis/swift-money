import SwiftMoney
import Testing

@Suite("Fixed Overflow Tests")
struct FixedOverflowTests {

    @Test("Reporting addition returns the sum, and flags overflow at the boundary")
    func addingReporting() {
        let inRange = Fixed(raw: 2).addingReportingOverflow(Fixed(raw: 3))
        #expect(inRange.value == Fixed(raw: 5))
        #expect(!inRange.overflow)

        #expect(Fixed(raw: .max).addingReportingOverflow(Fixed(raw: 1)).overflow)
    }

    @Test("Reporting subtraction returns the difference, and flags overflow at the boundary")
    func subtractingReporting() {
        let inRange = Fixed(raw: 5).subtractingReportingOverflow(Fixed(raw: 3))
        #expect(inRange.value == Fixed(raw: 2))
        #expect(!inRange.overflow)

        #expect(Fixed(raw: .min).subtractingReportingOverflow(Fixed(raw: 1)).overflow)
    }

    @Test("Reporting multiplication returns the product, and flags overflow at the boundary")
    func multiplyingFixedReporting() {
        let inRange = Fixed(raw: 3 * Fixed.scale).multipliedReportingOverflow(by: Fixed(raw: Fixed.scale / 4))
        #expect(inRange.value == Fixed(raw: 3 * Fixed.scale / 4))   // 3 × 0.25 = 0.75
        #expect(!inRange.overflow)

        #expect(Fixed(raw: .max).multipliedReportingOverflow(by: Fixed(raw: .max)).overflow)
    }

    @Test("Reporting integer multiplication returns the product, and flags overflow at the boundary")
    func multiplyingIntegerReporting() {
        let inRange = Fixed(raw: 2 * Fixed.scale).multipliedReportingOverflow(by: 3)
        #expect(inRange.value == Fixed(raw: 6 * Fixed.scale))
        #expect(!inRange.overflow)

        #expect(Fixed(raw: .max).multipliedReportingOverflow(by: 2).overflow)
    }

    @Test("A near-range product reports no overflow")
    func nearRangeNoOverflow() {
        let billion = Fixed(raw: 1_000_000_000 * Fixed.scale)

        #expect(!billion.multipliedReportingOverflow(by: billion).overflow)
    }

    @Test("Representable siblings return the value in range and nil at the boundary")
    func ifRepresentable() {
        #expect(Fixed(raw: 2).addingIfRepresentable(Fixed(raw: 3)) == Fixed(raw: 5))
        #expect(Fixed(raw: .max).addingIfRepresentable(Fixed(raw: 1)) == nil)

        #expect(Fixed(raw: 5).subtractingIfRepresentable(Fixed(raw: 3)) == Fixed(raw: 2))
        #expect(Fixed(raw: .min).subtractingIfRepresentable(Fixed(raw: 1)) == nil)

        #expect(Fixed(raw: 2 * Fixed.scale).multipliedIfRepresentable(by: 3) == Fixed(raw: 6 * Fixed.scale))
        #expect(Fixed(raw: .max).multipliedIfRepresentable(by: Fixed(raw: .max)) == nil)
        #expect(Fixed(raw: .max).multipliedIfRepresentable(by: 2) == nil)
    }
}
