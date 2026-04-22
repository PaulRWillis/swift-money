import Foundation
import SwiftMoney
import Testing

@Suite("Money - Custom String Convertible")
struct Money_CustomStringConvertibleTests {
    @Test("description equals formatted() output")
    func descriptionEqualsFormatted() {
        let money = Money<GBP>(minorUnits: 199)
        // description is defined as self.formatted() — the two must always be identical
        // regardless of the host locale.
        #expect(money.description == money.formatted())
    }

    @Test("description is non-empty for a positive value")
    func descriptionNonEmpty() {
        #expect(!Money<GBP>(minorUnits: 199).description.isEmpty)
    }

    @Test("description is non-empty for zero")
    func descriptionZeroNonEmpty() {
        #expect(!Money<GBP>.zero.description.isEmpty)
    }
}
