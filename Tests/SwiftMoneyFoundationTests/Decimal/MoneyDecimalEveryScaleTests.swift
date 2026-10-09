import Foundation
import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
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

@Suite("Money Decimal Every Scale Tests")
struct MoneyDecimalEveryScaleTests {

    @Test("Zero reads back digit for digit at every scale", arguments: [
        (0, "0"), (1, "0.0"), (2, "0.00"), (3, "0.000"), (4, "0.0000"), (5, "0.00000"), (6, "0.000000"),
        (7, "0.0000000"), (8, "0.00000000"), (9, "0.000000000"), (10, "0.0000000000"),
        (11, "0.00000000000"), (12, "0.000000000000"), (13, "0.0000000000000"),
        (14, "0.00000000000000"), (15, "0.000000000000000"), (16, "0.0000000000000000"),
        (17, "0.00000000000000000"), (18, "0.000000000000000000"),
    ])
    func zero(_ places: Int, _ expected: String) throws {
        try expectReadsBack(0, places: places, as: expected)
    }

    @Test("One minor unit reads back digit for digit at every scale", arguments: [
        (0, "1"), (1, "0.1"), (2, "0.01"), (3, "0.001"), (4, "0.0001"), (5, "0.00001"), (6, "0.000001"),
        (7, "0.0000001"), (8, "0.00000001"), (9, "0.000000001"), (10, "0.0000000001"),
        (11, "0.00000000001"), (12, "0.000000000001"), (13, "0.0000000000001"),
        (14, "0.00000000000001"), (15, "0.000000000000001"), (16, "0.0000000000000001"),
        (17, "0.00000000000000001"), (18, "0.000000000000000001"),
    ])
    func oneMinorUnit(_ places: Int, _ expected: String) throws {
        try expectReadsBack(1, places: places, as: expected)
    }

    @Test("Minus one minor unit reads back digit for digit at every scale", arguments: [
        (0, "-1"), (1, "-0.1"), (2, "-0.01"), (3, "-0.001"), (4, "-0.0001"), (5, "-0.00001"),
        (6, "-0.000001"), (7, "-0.0000001"), (8, "-0.00000001"), (9, "-0.000000001"),
        (10, "-0.0000000001"), (11, "-0.00000000001"), (12, "-0.000000000001"),
        (13, "-0.0000000000001"), (14, "-0.00000000000001"), (15, "-0.000000000000001"),
        (16, "-0.0000000000000001"), (17, "-0.00000000000000001"), (18, "-0.000000000000000001"),
    ])
    func minusOneMinorUnit(_ places: Int, _ expected: String) throws {
        try expectReadsBack(-1, places: places, as: expected)
    }

    // Trailing zeros are kept to the scale's places, never trimmed.
    @Test("A million minor units reads back digit for digit at every scale", arguments: [
        (0, "1000000"), (1, "100000.0"), (2, "10000.00"), (3, "1000.000"), (4, "100.0000"),
        (5, "10.00000"), (6, "1.000000"), (7, "0.1000000"), (8, "0.01000000"), (9, "0.001000000"),
        (10, "0.0001000000"), (11, "0.00001000000"), (12, "0.000001000000"), (13, "0.0000001000000"),
        (14, "0.00000001000000"), (15, "0.000000001000000"), (16, "0.0000000001000000"),
        (17, "0.00000000001000000"), (18, "0.000000000001000000"),
    ])
    func aMillionMinorUnits(_ places: Int, _ expected: String) throws {
        try expectReadsBack(1_000_000, places: places, as: expected)
    }

    @Test("Int64.max reads back digit for digit at every scale", arguments: [
        (0, "9223372036854775807"), (1, "922337203685477580.7"), (2, "92233720368547758.07"),
        (3, "9223372036854775.807"), (4, "922337203685477.5807"), (5, "92233720368547.75807"),
        (6, "9223372036854.775807"), (7, "922337203685.4775807"), (8, "92233720368.54775807"),
        (9, "9223372036.854775807"), (10, "922337203.6854775807"), (11, "92233720.36854775807"),
        (12, "9223372.036854775807"), (13, "922337.2036854775807"), (14, "92233.72036854775807"),
        (15, "9223.372036854775807"), (16, "922.3372036854775807"), (17, "92.23372036854775807"),
        (18, "9.223372036854775807"),
    ])
    func int64Max(_ places: Int, _ expected: String) throws {
        try expectReadsBack(.max, places: places, as: expected)
    }

    @Test("Int64.min reads back digit for digit at every scale", arguments: [
        (0, "-9223372036854775808"), (1, "-922337203685477580.8"), (2, "-92233720368547758.08"),
        (3, "-9223372036854775.808"), (4, "-922337203685477.5808"), (5, "-92233720368547.75808"),
        (6, "-9223372036854.775808"), (7, "-922337203685.4775808"), (8, "-92233720368.54775808"),
        (9, "-9223372036.854775808"), (10, "-922337203.6854775808"), (11, "-92233720.36854775808"),
        (12, "-9223372.036854775808"), (13, "-922337.2036854775808"), (14, "-92233.72036854775808"),
        (15, "-9223.372036854775808"), (16, "-922.3372036854775808"), (17, "-92.23372036854775808"),
        (18, "-9.223372036854775808"),
    ])
    func int64Min(_ places: Int, _ expected: String) throws {
        try expectReadsBack(.min, places: places, as: expected)
    }

    @Test("Int64.min + 1 reads back digit for digit at every scale", arguments: [
        (0, "-9223372036854775807"), (1, "-922337203685477580.7"), (2, "-92233720368547758.07"),
        (3, "-9223372036854775.807"), (4, "-922337203685477.5807"), (5, "-92233720368547.75807"),
        (6, "-9223372036854.775807"), (7, "-922337203685.4775807"), (8, "-92233720368.54775807"),
        (9, "-9223372036.854775807"), (10, "-922337203.6854775807"), (11, "-92233720.36854775807"),
        (12, "-9223372.036854775807"), (13, "-922337.2036854775807"), (14, "-92233.72036854775807"),
        (15, "-9223.372036854775807"), (16, "-922.3372036854775807"), (17, "-92.23372036854775807"),
        (18, "-9.223372036854775807"),
    ])
    func int64MinPlusOne(_ places: Int, _ expected: String) throws {
        try expectReadsBack(.min + 1, places: places, as: expected)
    }

    // The decimal, the description and the round trip, through both `Money` and a typed currency.
    private func expectReadsBack(_ minorUnits: Int64, places: Int, as written: String) throws {
        let expected = try #require(Decimal(string: written))
        let description = "PLACES\(places) \(written)"
        let type = typed[places]

        let money = Money(minorUnits: minorUnits, currency: type.currency)
        #expect(Decimal(majorUnitsOf: money) == expected)
        #expect(String(describing: money) == description)
        #expect(Money(majorUnits: Decimal(majorUnitsOf: money), currency: type.currency) == money)

        expectTyped(type, minorUnits, expected, description)
    }

    private func expectTyped<C: CurrencyType>(_: C.Type, _ minorUnits: Int64, _ expected: Decimal, _ description: String) {
        let amount = MoneyOf<C>(minorUnits: minorUnits)
        #expect(Decimal(majorUnitsOf: amount) == expected)
        #expect(String(describing: amount) == description)
        #expect(MoneyOf<C>(majorUnits: Decimal(majorUnitsOf: amount)) == amount)
    }
}
