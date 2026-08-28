import SwiftMoneyCore
import Testing

private enum Tenths: CurrencyType {
    static let currency = customCurrency(code: "TEN", unitScale: 10)
}

// Seventeen decimal places, near the finest a scale can name.
private enum Seventeen: CurrencyType {
    static let currency = customCurrency(code: "FIN", unitScale: 100_000_000_000_000_000)
}

private let loyaltyPoints = customCurrency(code: "LTY", unitScale: 1)

@Suite("Money Parsing Tests")
struct MoneyParsingTests {

    @Test(
        "A dot means major units and no dot means the smallest units",
        arguments: [
            ("4.99", 4_99),
            ("499", 4_99),
            ("0.05", 5),
            ("5", 5),
            ("0.00", 0),
            ("0", 0),
        ]
    )
    func bothSpellings(_ text: String, _ expected: Int64) throws {
        #expect(try #require(GBP(string: text)) == GBP(minorUnits: expected))
    }

    @Test("Fewer decimals than the currency divides into are filled out")
    func shortDecimal() throws {
        #expect(try #require(GBP(string: "4.9")) == GBP(minorUnits: 4_90))
        #expect(GBP(string: "4.") == nil)
    }

    @Test("A negative amount parses in either spelling")
    func negative() throws {
        #expect(try #require(GBP(string: "-4.99")) == GBP(minorUnits: -4_99))
        #expect(try #require(GBP(string: "-499")) == GBP(minorUnits: -4_99))
    }

    @Test("A code may be left out where the type names the currency, and must match where given")
    func codeOptionalForATypedAmount() throws {
        #expect(try #require(GBP(string: "GBP 4.99")) == GBP(minorUnits: 4_99))
        #expect(GBP(string: "USD 4.99") == nil)
    }

    @Test("A code may be left out where the caller names the currency, and must match where given")
    func codeOptionalWhenTheCallerNamesIt() throws {
        let expected = Money(minorUnits: 250, currency: loyaltyPoints)

        #expect(try #require(Money(string: "250", currency: loyaltyPoints)) == expected)
        #expect(try #require(Money(string: "LTY 250", currency: loyaltyPoints)) == expected)
        #expect(Money(string: "GBP 250", currency: loyaltyPoints) == nil)
    }

    @Test("A code is required where nothing else names the currency")
    func codeRequiredForARuntimeAmount() throws {
        #expect(try #require(Money(string: "GBP 4.99")) == Money(minorUnits: 4_99, currency: .gbp))
        #expect(Money(string: "4.99") == nil)
        #expect(Money(string: "499") == nil)
    }

    @Test("A code outside ISO 4217 does not resolve on its own")
    func unknownCode() {
        #expect(Money(string: "LTY 250") == nil)
    }

    @Test(
        "Something that is not a code where a code belongs is refused",
        arguments: ["GB 4.99", "GBPGBPGBP 4.99", "G-P 4.99", "gbp! 4.99"]
    )
    func malformedCode(_ text: String) {
        #expect(GBP(string: text) == nil)
        #expect(Money(string: text) == nil)
        #expect(Money(string: text, currency: loyaltyPoints) == nil)
    }

    @Test("A lowercase code names the same currency as an uppercase one")
    func lowercaseCode() throws {
        #expect(try #require(GBP(string: "gbp 4.99")) == GBP(minorUnits: 4_99))
        #expect(try #require(Money(string: "gbp 4.99")) == Money(minorUnits: 4_99, currency: .gbp))
        #expect(try #require(Money(string: "lty 250", currency: loyaltyPoints))
            == Money(minorUnits: 250, currency: loyaltyPoints))
    }

    // The rule is one test, not two: a decimal is accepted exactly when it converts to a whole
    // number of the currency's smallest units.
    @Test(
        "An amount finer than the currency divides is refused rather than rounded",
        arguments: [
            "4.999",     // a hundredth of a penny
            "4.991",
            "0.001",
        ]
    )
    func excessPrecision(_ text: String) {
        #expect(GBP(string: text) == nil)
    }

    // A sender formatting to a fixed width pads with zeros, and eighteen places is what a system
    // built around wei emits. The amount is still exactly £4.99, so refusing it would be wrong.
    @Test(
        "Zeros padding an amount out to any width do not change it",
        arguments: [
            "4.99",
            "4.990",
            "4.99000000000000000",    // seventeen places
            "4.990000000000000000",   // eighteen, where the scaled fraction outgrows a UInt64
            "4.9900000000000000000",  // nineteen
        ]
    )
    func paddingZeros(_ text: String) throws {
        #expect(try #require(GBP(string: text)) == GBP(minorUnits: 4_99))
    }

    @Test("Padding does not make an amount the currency cannot hold acceptable")
    func paddingDoesNotWidenPrecision() {
        #expect(GBP(string: "4.999000000000000000") == nil)
        #expect(MoneyOf<Tenths>(string: "0.640000000000000000") == nil)
    }

    @Test("A currency far finer than sterling parses its own smallest units")
    func veryFineCurrency() throws {
        let amount = try #require(MoneyOf<Seventeen>(string: "0.00000000000012345"))

        #expect(amount == MoneyOf<Seventeen>(minorUnits: 12345))
    }

    @Test("A currency dividing into tenths takes the decimals it can hold")
    func currencyDividingIntoTenths() throws {
        #expect(try #require(MoneyOf<Tenths>(string: "0.6")) == MoneyOf<Tenths>(minorUnits: 6))
        #expect(try #require(MoneyOf<Tenths>(string: "1.0")) == MoneyOf<Tenths>(minorUnits: 10))
        #expect(try #require(MoneyOf<Tenths>(string: "3")) == MoneyOf<Tenths>(minorUnits: 3))
        #expect(MoneyOf<Tenths>(string: "0.64") == nil)
    }

    @Test(
        "Anything that is not an amount is refused",
        arguments: ["", " ", "GBP", "GBP ", "four", "4.9.9", "4,99", "£4.99", "4 99", "0x10"]
    )
    func refusesRubbish(_ text: String) {
        #expect(GBP(string: text) == nil)
    }

    @Test("An amount too large for the range is refused rather than wrapped")
    func overflow() {
        #expect(GBP(string: "999999999999999999999999999999") == nil)
        #expect(GBP(string: "92233720368547758.08") == nil)
        #expect(Money(string: "GBP 99999999999999999999") == nil)
    }

    @Test("The extremes of the range parse")
    func extremes() throws {
        #expect(try #require(GBP(string: "-92233720368547758.08")) == GBP.min)
        #expect(try #require(GBP(string: "92233720368547758.07")) == GBP.max)
    }

    @Test("Every amount this library writes, it reads back")
    func roundTrip() throws {
        let amounts: [Money] = [
            Money(minorUnits: 4_99, currency: .gbp),
            Money(minorUnits: -4_99, currency: .gbp),
            Money(minorUnits: 0, currency: .gbp),
            Money(minorUnits: 499, currency: .jpy),
            Money(minorUnits: 1, currency: .kwd),
            Money(minorUnits: Int64.max, currency: .gbp),
            Money(minorUnits: Int64.min, currency: .gbp),
        ]

        for amount in amounts {
            #expect(try #require(Money(string: String(describing: amount))) == amount)
        }
    }
}
