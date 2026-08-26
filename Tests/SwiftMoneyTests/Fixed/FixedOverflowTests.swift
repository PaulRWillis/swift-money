import SwiftMoney
import Testing

@Suite("Fixed Overflow Tests")
struct FixedOverflowTests {

    // `exponent: -18` names the least significant digit, so a `significand:` there is the stored value —
    // the way to reach the extremes through the public interface.
    @Test("Reporting arithmetic returns the value in range and flags overflow at the boundary")
    func reportingForms() throws {
        let largest = try #require(Fixed(significand: .max, exponent: -18))
        let mostNegative = try #require(Fixed(significand: .min, exponent: -18))
        let smallest = try #require(Fixed(significand: 1, exponent: -18))

        let sum = Fixed(2).addingReportingOverflow(Fixed(3))
        #expect(sum.value == Fixed(5))
        #expect(!sum.overflow)
        #expect(largest.addingReportingOverflow(smallest).overflow)

        let difference = Fixed(5).subtractingReportingOverflow(Fixed(3))
        #expect(difference.value == Fixed(2))
        #expect(!difference.overflow)
        #expect(mostNegative.subtractingReportingOverflow(smallest).overflow)

        #expect(largest.multipliedReportingOverflow(by: largest).overflow)
        #expect(largest.multipliedReportingOverflow(by: 2).overflow)
        #expect(Fixed(1).multipliedReportingOverflow(by: UInt128.max).overflow)   // factor too large for Int128
        #expect(!Fixed(1_000_000_000).multipliedReportingOverflow(by: Fixed(1_000_000_000)).overflow)
    }

    @Test("Representable siblings return the value in range and nil at the boundary")
    func ifRepresentable() throws {
        let largest = try #require(Fixed(significand: .max, exponent: -18))
        let smallest = try #require(Fixed(significand: 1, exponent: -18))

        #expect(Fixed(2).addingIfRepresentable(Fixed(3)) == Fixed(5))
        #expect(largest.addingIfRepresentable(smallest) == nil)

        #expect(Fixed(5).subtractingIfRepresentable(Fixed(3)) == Fixed(2))

        #expect(Fixed(2).multipliedIfRepresentable(by: 3) == Fixed(6))
        #expect(largest.multipliedIfRepresentable(by: largest) == nil)
        #expect(largest.multipliedIfRepresentable(by: 2) == nil)
    }
}
