import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

// One typed currency per scale, indexed by its number of decimal places. Past four places no ISO
// currency reaches, so all are custom.
private enum Places0: CurrencyType { static let currency = customCurrency(code: "PLACES0", unitScale: 1) }
private enum Places1: CurrencyType { static let currency = customCurrency(code: "PLACES1", unitScale: 10) }
private enum Places2: CurrencyType { static let currency = customCurrency(code: "PLACES2", unitScale: 100) }
private enum Places3: CurrencyType { static let currency = customCurrency(code: "PLACES3", unitScale: 1_000) }
private enum Places4: CurrencyType { static let currency = customCurrency(code: "PLACES4", unitScale: 10_000) }
private enum Places5: CurrencyType { static let currency = customCurrency(code: "PLACES5", unitScale: 100_000) }
private enum Places6: CurrencyType { static let currency = customCurrency(code: "PLACES6", unitScale: 1_000_000) }
private enum Places7: CurrencyType { static let currency = customCurrency(code: "PLACES7", unitScale: 10_000_000) }
private enum Places8: CurrencyType { static let currency = customCurrency(code: "PLACES8", unitScale: 100_000_000) }
private enum Places9: CurrencyType { static let currency = customCurrency(code: "PLACES9", unitScale: 1_000_000_000) }
private enum Places10: CurrencyType { static let currency = customCurrency(code: "PLACES10", unitScale: 10_000_000_000) }
private enum Places11: CurrencyType { static let currency = customCurrency(code: "PLACES11", unitScale: 100_000_000_000) }
private enum Places12: CurrencyType { static let currency = customCurrency(code: "PLACES12", unitScale: 1_000_000_000_000) }
private enum Places13: CurrencyType { static let currency = customCurrency(code: "PLACES13", unitScale: 10_000_000_000_000) }
private enum Places14: CurrencyType { static let currency = customCurrency(code: "PLACES14", unitScale: 100_000_000_000_000) }
private enum Places15: CurrencyType { static let currency = customCurrency(code: "PLACES15", unitScale: 1_000_000_000_000_000) }
private enum Places16: CurrencyType { static let currency = customCurrency(code: "PLACES16", unitScale: 10_000_000_000_000_000) }
private enum Places17: CurrencyType { static let currency = customCurrency(code: "PLACES17", unitScale: 100_000_000_000_000_000) }
private enum Places18: CurrencyType { static let currency = customCurrency(code: "PLACES18", unitScale: 1_000_000_000_000_000_000) }

private let typedCurrencies: [any CurrencyType.Type] = [
    Places0.self, Places1.self, Places2.self, Places3.self, Places4.self, Places5.self, Places6.self,
    Places7.self, Places8.self, Places9.self, Places10.self, Places11.self, Places12.self, Places13.self,
    Places14.self, Places15.self, Places16.self, Places17.self, Places18.self,
]

@Suite("Money Decimal Every Scale Tests")
struct MoneyDecimalEveryScaleTests {

    @Test(
        "Major units read back digit for digit at every scale, as a decimal and as a description",
        arguments: [
            (0, 0, "0"),
            (0, 1, "1"),
            (0, -1, "-1"),
            (0, 1_000_000, "1000000"),
            (0, Int64.max, "9223372036854775807"),
            (0, Int64.min, "-9223372036854775808"),
            (0, Int64.min + 1, "-9223372036854775807"),
            (1, 0, "0.0"),
            (1, 1, "0.1"),
            (1, -1, "-0.1"),
            (1, 1_000_000, "100000.0"),
            (1, Int64.max, "922337203685477580.7"),
            (1, Int64.min, "-922337203685477580.8"),
            (1, Int64.min + 1, "-922337203685477580.7"),
            (2, 0, "0.00"),
            (2, 1, "0.01"),
            (2, -1, "-0.01"),
            (2, 1_000_000, "10000.00"),
            (2, Int64.max, "92233720368547758.07"),
            (2, Int64.min, "-92233720368547758.08"),
            (2, Int64.min + 1, "-92233720368547758.07"),
            (3, 0, "0.000"),
            (3, 1, "0.001"),
            (3, -1, "-0.001"),
            (3, 1_000_000, "1000.000"),
            (3, Int64.max, "9223372036854775.807"),
            (3, Int64.min, "-9223372036854775.808"),
            (3, Int64.min + 1, "-9223372036854775.807"),
            (4, 0, "0.0000"),
            (4, 1, "0.0001"),
            (4, -1, "-0.0001"),
            (4, 1_000_000, "100.0000"),
            (4, Int64.max, "922337203685477.5807"),
            (4, Int64.min, "-922337203685477.5808"),
            (4, Int64.min + 1, "-922337203685477.5807"),
            (5, 0, "0.00000"),
            (5, 1, "0.00001"),
            (5, -1, "-0.00001"),
            (5, 1_000_000, "10.00000"),
            (5, Int64.max, "92233720368547.75807"),
            (5, Int64.min, "-92233720368547.75808"),
            (5, Int64.min + 1, "-92233720368547.75807"),
            (6, 0, "0.000000"),
            (6, 1, "0.000001"),
            (6, -1, "-0.000001"),
            (6, 1_000_000, "1.000000"),
            (6, Int64.max, "9223372036854.775807"),
            (6, Int64.min, "-9223372036854.775808"),
            (6, Int64.min + 1, "-9223372036854.775807"),
            (7, 0, "0.0000000"),
            (7, 1, "0.0000001"),
            (7, -1, "-0.0000001"),
            (7, 1_000_000, "0.1000000"),
            (7, Int64.max, "922337203685.4775807"),
            (7, Int64.min, "-922337203685.4775808"),
            (7, Int64.min + 1, "-922337203685.4775807"),
            (8, 0, "0.00000000"),
            (8, 1, "0.00000001"),
            (8, -1, "-0.00000001"),
            (8, 1_000_000, "0.01000000"),
            (8, Int64.max, "92233720368.54775807"),
            (8, Int64.min, "-92233720368.54775808"),
            (8, Int64.min + 1, "-92233720368.54775807"),
            (9, 0, "0.000000000"),
            (9, 1, "0.000000001"),
            (9, -1, "-0.000000001"),
            (9, 1_000_000, "0.001000000"),
            (9, Int64.max, "9223372036.854775807"),
            (9, Int64.min, "-9223372036.854775808"),
            (9, Int64.min + 1, "-9223372036.854775807"),
            (10, 0, "0.0000000000"),
            (10, 1, "0.0000000001"),
            (10, -1, "-0.0000000001"),
            (10, 1_000_000, "0.0001000000"),
            (10, Int64.max, "922337203.6854775807"),
            (10, Int64.min, "-922337203.6854775808"),
            (10, Int64.min + 1, "-922337203.6854775807"),
            (11, 0, "0.00000000000"),
            (11, 1, "0.00000000001"),
            (11, -1, "-0.00000000001"),
            (11, 1_000_000, "0.00001000000"),
            (11, Int64.max, "92233720.36854775807"),
            (11, Int64.min, "-92233720.36854775808"),
            (11, Int64.min + 1, "-92233720.36854775807"),
            (12, 0, "0.000000000000"),
            (12, 1, "0.000000000001"),
            (12, -1, "-0.000000000001"),
            (12, 1_000_000, "0.000001000000"),
            (12, Int64.max, "9223372.036854775807"),
            (12, Int64.min, "-9223372.036854775808"),
            (12, Int64.min + 1, "-9223372.036854775807"),
            (13, 0, "0.0000000000000"),
            (13, 1, "0.0000000000001"),
            (13, -1, "-0.0000000000001"),
            (13, 1_000_000, "0.0000001000000"),
            (13, Int64.max, "922337.2036854775807"),
            (13, Int64.min, "-922337.2036854775808"),
            (13, Int64.min + 1, "-922337.2036854775807"),
            (14, 0, "0.00000000000000"),
            (14, 1, "0.00000000000001"),
            (14, -1, "-0.00000000000001"),
            (14, 1_000_000, "0.00000001000000"),
            (14, Int64.max, "92233.72036854775807"),
            (14, Int64.min, "-92233.72036854775808"),
            (14, Int64.min + 1, "-92233.72036854775807"),
            (15, 0, "0.000000000000000"),
            (15, 1, "0.000000000000001"),
            (15, -1, "-0.000000000000001"),
            (15, 1_000_000, "0.000000001000000"),
            (15, Int64.max, "9223.372036854775807"),
            (15, Int64.min, "-9223.372036854775808"),
            (15, Int64.min + 1, "-9223.372036854775807"),
            (16, 0, "0.0000000000000000"),
            (16, 1, "0.0000000000000001"),
            (16, -1, "-0.0000000000000001"),
            (16, 1_000_000, "0.0000000001000000"),
            (16, Int64.max, "922.3372036854775807"),
            (16, Int64.min, "-922.3372036854775808"),
            (16, Int64.min + 1, "-922.3372036854775807"),
            (17, 0, "0.00000000000000000"),
            (17, 1, "0.00000000000000001"),
            (17, -1, "-0.00000000000000001"),
            (17, 1_000_000, "0.00000000001000000"),
            (17, Int64.max, "92.23372036854775807"),
            (17, Int64.min, "-92.23372036854775808"),
            (17, Int64.min + 1, "-92.23372036854775807"),
            (18, 0, "0.000000000000000000"),
            (18, 1, "0.000000000000000001"),
            (18, -1, "-0.000000000000000001"),
            (18, 1_000_000, "0.000000000001000000"),
            (18, Int64.max, "9.223372036854775807"),
            (18, Int64.min, "-9.223372036854775808"),
            (18, Int64.min + 1, "-9.223372036854775807"),
        ] as [(places: Int, minorUnits: Int64, majorUnits: String)]
    )
    func readsBackAtEveryScale(_ testCase: (places: Int, minorUnits: Int64, majorUnits: String)) throws {
        let expected = try #require(Decimal(string: testCase.majorUnits))
        let description = "PLACES\(testCase.places) \(testCase.majorUnits)"
        let type = typedCurrencies[testCase.places]

        let money = Money(minorUnits: testCase.minorUnits, currency: type.currency)
        #expect(Decimal(majorUnitsOf: money) == expected)
        #expect(String(describing: money) == description)
        #expect(Money(majorUnits: Decimal(majorUnitsOf: money), currency: type.currency) == money)

        expectTyped(type, minorUnits: testCase.minorUnits, readsBackAs: expected, description: description)
    }

    private func expectTyped<C: CurrencyType>(
        _: C.Type,
        minorUnits: Int64,
        readsBackAs expected: Decimal,
        description: String
    ) {
        let amount = MoneyOf<C>(minorUnits: minorUnits)

        #expect(Decimal(majorUnitsOf: amount) == expected)
        #expect(String(describing: amount) == description)
        #expect(MoneyOf<C>(majorUnits: Decimal(majorUnitsOf: amount)) == amount)
    }
}
