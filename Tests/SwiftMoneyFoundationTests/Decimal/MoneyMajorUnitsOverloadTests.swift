import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

// With Foundation imported, a literal count could reach the `Decimal` overload or the integer ones.
// Whichever the compiler picks, the amount must be the same.
@Suite("Whole major units beside the Decimal overload")
struct MoneyMajorUnitsOverloadTests {

    @Test("An integer literal still builds fifteen pounds")
    func integerLiteral() {
        #expect(GBP(majorUnits: 15) == GBP(minorUnits: 15_00))
        #expect(Money(majorUnits: 15, currency: .gbp) == Money(minorUnits: 15_00, currency: .gbp))
    }

    @Test("The integer and Decimal overloads agree")
    func overloadsAgree() {
        #expect(GBP(majorUnits: 15 as Int) == GBP(majorUnits: Decimal(15)))
        #expect(Money(majorUnits: 15 as Int, currency: .jpy) == Money(majorUnits: Decimal(15), currency: .jpy))
    }
}
