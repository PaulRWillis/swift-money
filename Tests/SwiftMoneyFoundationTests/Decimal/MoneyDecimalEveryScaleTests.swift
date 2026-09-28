import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

// One typed currency per number of decimal places. Past four places no ISO currency reaches.
private enum P0: CurrencyType { static let currency = customCurrency(code: "PLACES0", unitScale: 1) }
private enum P1: CurrencyType { static let currency = customCurrency(code: "PLACES1", unitScale: 10) }
private enum P2: CurrencyType { static let currency = customCurrency(code: "PLACES2", unitScale: 100) }
private enum P3: CurrencyType { static let currency = customCurrency(code: "PLACES3", unitScale: 1_000) }
private enum P4: CurrencyType { static let currency = customCurrency(code: "PLACES4", unitScale: 10_000) }
private enum P5: CurrencyType { static let currency = customCurrency(code: "PLACES5", unitScale: 100_000) }
private enum P6: CurrencyType { static let currency = customCurrency(code: "PLACES6", unitScale: 1_000_000) }
private enum P7: CurrencyType { static let currency = customCurrency(code: "PLACES7", unitScale: 10_000_000) }
private enum P8: CurrencyType { static let currency = customCurrency(code: "PLACES8", unitScale: 100_000_000) }
private enum P9: CurrencyType { static let currency = customCurrency(code: "PLACES9", unitScale: 1_000_000_000) }
private enum P10: CurrencyType { static let currency = customCurrency(code: "PLACES10", unitScale: 10_000_000_000) }
private enum P11: CurrencyType { static let currency = customCurrency(code: "PLACES11", unitScale: 100_000_000_000) }
private enum P12: CurrencyType { static let currency = customCurrency(code: "PLACES12", unitScale: 1_000_000_000_000) }
private enum P13: CurrencyType { static let currency = customCurrency(code: "PLACES13", unitScale: 10_000_000_000_000) }
private enum P14: CurrencyType { static let currency = customCurrency(code: "PLACES14", unitScale: 100_000_000_000_000) }
private enum P15: CurrencyType { static let currency = customCurrency(code: "PLACES15", unitScale: 1_000_000_000_000_000) }
private enum P16: CurrencyType { static let currency = customCurrency(code: "PLACES16", unitScale: 10_000_000_000_000_000) }
private enum P17: CurrencyType { static let currency = customCurrency(code: "PLACES17", unitScale: 100_000_000_000_000_000) }
private enum P18: CurrencyType { static let currency = customCurrency(code: "PLACES18", unitScale: 1_000_000_000_000_000_000) }

private let typed: [any CurrencyType.Type] = [
    P0.self, P1.self, P2.self, P3.self, P4.self, P5.self, P6.self, P7.self, P8.self, P9.self,
    P10.self, P11.self, P12.self, P13.self, P14.self, P15.self, P16.self, P17.self, P18.self,
]

private let amounts: [Int64] = [0, 1, -1, 1_000_000, .max, .min, .min + 1]

// The amount in major units, written out by hand: digits padded to one past the places, then a point.
private func majorUnits(_ minorUnits: Int64, places: Int) -> String {
    let digits = String(minorUnits.magnitude)
    let padded = String(repeating: "0", count: max(0, places + 1 - digits.count)) + digits
    let point = places == 0 ? "" : "." + padded.suffix(places)
    return (minorUnits < 0 ? "-" : "") + padded.dropLast(places) + point
}

@Suite("Money Decimal Every Scale Tests")
struct MoneyDecimalEveryScaleTests {

    @Test("Major units read back digit for digit at every scale, as a decimal and as a description", arguments: 0 ... 18, amounts)
    func readsBackAtEveryScale(_ places: Int, _ minorUnits: Int64) throws {
        let written = majorUnits(minorUnits, places: places)
        let expected = try #require(Decimal(string: written))
        let type = typed[places]

        let money = Money(minorUnits: minorUnits, currency: type.currency)
        #expect(Decimal(majorUnitsOf: money) == expected)
        #expect(String(describing: money) == "PLACES\(places) \(written)")
        #expect(Money(majorUnits: Decimal(majorUnitsOf: money), currency: type.currency) == money)

        expectTyped(type, minorUnits, expected, "PLACES\(places) \(written)")
    }

    private func expectTyped<C: CurrencyType>(_: C.Type, _ minorUnits: Int64, _ expected: Decimal, _ description: String) {
        let amount = MoneyOf<C>(minorUnits: minorUnits)
        #expect(Decimal(majorUnitsOf: amount) == expected)
        #expect(String(describing: amount) == description)
        #expect(MoneyOf<C>(majorUnits: Decimal(majorUnitsOf: amount)) == amount)
    }
}
