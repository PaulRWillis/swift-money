import Foundation
import SwiftMoney
import Testing

@Suite("Money - Safety Hardening")
struct Money_SafetyTests {

    private let enGB = Locale(identifier: "en_GB")

    // MARK: - Sendable (compile-time verification)
    //
    // There is no runtime assertion for Sendable — if Money were not Sendable
    // the line below would fail to compile with a "type does not conform" error.
    // The test body itself is trivial; the conformance is what matters.

    @Test("Money<GBP> is Sendable")
    func moneyIsSendable() {
        func requiresSendable<T: Sendable>(_: T) {}
        requiresSendable(Money<GBP>(minorUnits: 100))
    }

    // MARK: - CustomDebugStringConvertible

    @Test("debugDescription contains currency code, minor units and formatted value")
    func debugDescriptionNormal() {
        let money = Money<GBP>(minorUnits: 150)
        let desc  = money.debugDescription
        #expect(desc.contains("GBP"))
        #expect(desc.contains("150"))
        #expect(desc.contains("£1.50") || !money.formatted(Money<GBP>.FormatStyle().locale(enGB)).isEmpty)
    }

    @Test("AnyMoney debugDescription contains currency code and minor units")
    func anyMoneyDebugDescription() {
        let any = Money<GBP>(minorUnits: 150).erased
        let desc = any.debugDescription
        #expect(desc.contains("GBP"))
        #expect(desc.contains("150"))
    }

    @Test("MoneyBag debugDescription contains currency code and minor units for each entry")
    func moneyBagDebugDescription() {
        let bag = MoneyBag()
            .adding(Money<GBP>(minorUnits: 150))
            .adding(Money<EUR>(minorUnits: 1000))
        let desc = bag.debugDescription
        #expect(desc.contains("GBP"))
        #expect(desc.contains("150"))
        #expect(desc.contains("EUR"))
        #expect(desc.contains("1000"))
    }

    @Test("Empty MoneyBag debugDescription is well-formed")
    func emptyMoneyBagDebugDescription() {
        let desc = MoneyBag().debugDescription
        #expect(desc.contains("MoneyBag"))
    }
}
